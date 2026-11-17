//
//  MainViewModel.swift
//  SZSIM
//

import AppKit
import CoreLocation
import Observation
import os

/// Orchestrates the main screen: simulators, points, route, playback, and sending
/// to `simctl`. The `PlaybackEngine`'s `tick()` is driven by a loop whose cadence
/// is the send interval; each tick pushes the current coordinate to the simulator.
@MainActor
@Observable
final class MainViewModel {
    private let simctl: SimctlService
    private let routeBuilder: RouteBuilder
    private let geocoder: any ReverseGeocoding
    let playback: PlaybackEngine
    let search: LocationSearchService

    private static let logger = Logger(subsystem: "com.szsim.app", category: "playback")

    var devices: [SimulatorDevice] = []
    var selectedDeviceID: SimulatorDevice.ID?
    private(set) var waypoints: [Waypoint] = []
    var mode: RouteMode = .streets
    private(set) var polyline: [RouteCoordinate] = []
    private(set) var distanceMeters: Double = 0
    var errorMessage: String?

    /// Point vs route mode. Point is the default.
    var panelMode: PanelMode = .point
    /// The point currently selected on the map (Point mode).
    var selectedPoint: PointSelection?
    /// Transient confirmation message shown as a toast.
    var toast: String?

    /// Increments on each route loaded/imported, signaling the map to frame it.
    private(set) var mapFitToken = 0

    @ObservationIgnored private var tickTask: Task<Void, Never>?
    @ObservationIgnored private var geocodeTask: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?

    init(
        simctl: SimctlService = SimctlService(),
        routeBuilder: RouteBuilder = RouteBuilder(),
        geocoder: any ReverseGeocoding = GeocodingService(),
        playback: PlaybackEngine? = nil,
        search: LocationSearchService? = nil
    ) {
        self.simctl = simctl
        self.routeBuilder = routeBuilder
        self.geocoder = geocoder
        self.playback = playback ?? PlaybackEngine()
        self.search = search ?? LocationSearchService()
    }

    // MARK: - Derived

    var selectedDevice: SimulatorDevice? {
        devices.first { $0.id == selectedDeviceID }
    }

    var hasBootedDevice: Bool {
        devices.contains { $0.isBooted }
    }

    var canPlay: Bool {
        !polyline.isEmpty && selectedDevice != nil
    }

    var currentCoordinate: RouteCoordinate? { playback.currentCoordinate }
    var currentHeading: Double { playback.currentHeading }
    var currentSpeedMetersPerSecond: Double { playback.currentSpeedMetersPerSecond }

    // MARK: - Simulators

    func refreshDevices() async {
        do {
            devices = try await simctl.bootedDevices()
            if selectedDevice == nil {
                selectedDeviceID = devices.first { $0.isBooted }?.id
            }
        } catch {
            errorMessage = "Failed to list simulators: \(error.localizedDescription)"
        }
    }

    /// Opens the Simulator app (resolved by bundle id, regardless of the Xcode path).
    func openSimulator() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iphonesimulator") else {
            errorMessage = "Simulator.app not found. Check your Xcode installation."
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    // MARK: - Points

    func addWaypoint(_ coordinate: CLLocationCoordinate2D) {
        waypoints.append(Waypoint(coordinate: coordinate, kind: .destination))
        normalizeKinds()
    }

    func removeWaypoint(id: UUID) {
        waypoints.removeAll { $0.id == id }
        normalizeKinds()
    }

    private func normalizeKinds() {
        guard !waypoints.isEmpty else { return }
        for index in waypoints.indices {
            if index == 0 {
                waypoints[index].kind = .origin
            } else if index == waypoints.count - 1 {
                waypoints[index].kind = .destination
            } else {
                waypoints[index].kind = .stop
            }
        }
    }

    // MARK: - Point

    /// Selects a point from a map tap or search result, resolving its address once.
    func selectPoint(_ coordinate: CLLocationCoordinate2D) {
        selectedPoint = PointSelection(coordinate: RouteCoordinate(coordinate), isResolvingAddress: true)
        geocodeTask?.cancel()
        geocodeTask = Task { [weak self] in
            guard let self else { return }
            let address = await self.geocoder.address(for: coordinate)
            if Task.isCancelled { return }
            self.selectedPoint?.address = address
            self.selectedPoint?.isResolvingAddress = false
        }
    }

    /// Fills the selection from a stored point, without reverse geocoding again.
    func selectSavedPoint(_ point: SavedPoint) {
        geocodeTask?.cancel()
        selectedPoint = PointSelection(
            name: point.name,
            coordinate: RouteCoordinate(latitude: point.latitude, longitude: point.longitude),
            address: point.address
        )
    }

    /// Sends the selected point to the simulator once (no timer, no playback).
    func setSelectedPointOnSimulator() async {
        guard let device = selectedDevice, let point = selectedPoint else { return }
        do {
            try await simctl.setLocation(udid: device.udid, coordinate: point.coordinate.coordinate)
            selectedPoint?.lastSend = PointSend(deviceName: device.name, date: .now)
            showToast("Set on \(device.name)")
        } catch {
            Self.logger.error("Failed to send location: \(error.localizedDescription)")
            errorMessage = "Failed to send location: \(error.localizedDescription)"
        }
    }

    /// Sends a saved point straight to the simulator. Returns `true` on success so
    /// the caller can update `lastUsedAt`.
    func sendSavedPoint(_ point: SavedPoint) async -> Bool {
        guard let device = selectedDevice else {
            errorMessage = "Select a simulator first."
            return false
        }
        do {
            try await simctl.setLocation(udid: device.udid, coordinate: point.coordinate)
            showToast("Set on \(device.name)")
            return true
        } catch {
            Self.logger.error("Failed to send location: \(error.localizedDescription)")
            errorMessage = "Failed to send location: \(error.localizedDescription)"
            return false
        }
    }

    /// Shows a transient confirmation message, clearing it after a short delay.
    func showToast(_ message: String) {
        toast = message
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            if Task.isCancelled { return }
            self?.toast = nil
        }
    }

    // MARK: - Route

    /// Adopts an imported polyline (GPX/KML) as the current route, deriving
    /// origin/destination for display. Does not call `MKDirections`.
    func importPolyline(_ coordinates: [RouteCoordinate]) {
        guard let first = coordinates.first else { return }
        polyline = coordinates
        distanceMeters = zip(coordinates, coordinates.dropFirst()).reduce(0) { total, pair in
            total + GeoMath.distance(from: pair.0, to: pair.1)
        }
        mode = .straight
        waypoints = [Waypoint(coordinate: first.coordinate, kind: .origin)]
        if let last = coordinates.last, coordinates.count > 1 {
            waypoints.append(Waypoint(coordinate: last.coordinate, kind: .destination))
        }
        playback.load(polyline: coordinates)
        mapFitToken += 1
    }

    /// Restores a saved route from cache, without recomputing via `MKDirections`.
    func load(_ route: SavedRoute) {
        waypoints = route.waypoints
        mode = route.mode
        playback.profile = route.profile
        playback.speed = route.speed
        polyline = route.polyline
        distanceMeters = route.distanceMeters
        playback.load(polyline: route.polyline)
        mapFitToken += 1
    }

    func rebuildRoute() async {
        guard waypoints.count >= 2 else {
            polyline = []
            distanceMeters = 0
            playback.load(polyline: [])
            return
        }
        do {
            let built = try await routeBuilder.build(waypoints: waypoints, mode: mode, profile: playback.profile)
            polyline = built.polyline
            distanceMeters = built.distanceMeters
            playback.load(polyline: built.polyline)
        } catch {
            errorMessage = "Failed to build route: \(error.localizedDescription)"
            polyline = []
            distanceMeters = 0
            playback.load(polyline: [])
        }
    }

    // MARK: - Playback

    func play() {
        guard canPlay else { return }
        playback.play()
        startTickLoop()
    }

    func pause() {
        playback.pause()
        tickTask?.cancel()
    }

    func reset() {
        playback.reset()
        tickTask?.cancel()
    }

    private func startTickLoop() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            guard let self else { return }
            while self.playback.isPlaying {
                try? await Task.sleep(for: .seconds(self.playback.tickInterval))
                if Task.isCancelled { return }
                await self.advanceAndSend()
            }
        }
    }

    /// Advances one tick and sends the current coordinate to the selected simulator.
    func advanceAndSend() async {
        playback.tick()
        await sendCurrentLocation()
    }

    private func sendCurrentLocation() async {
        guard let device = selectedDevice, let coordinate = playback.currentCoordinate else { return }
        do {
            try await simctl.setLocation(udid: device.udid, coordinate: coordinate.coordinate)
        } catch {
            Self.logger.error("Failed to send location: \(error.localizedDescription)")
            errorMessage = "Failed to send location: \(error.localizedDescription)"
        }
    }
}
