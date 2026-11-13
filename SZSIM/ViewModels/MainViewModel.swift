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

    /// Increments on each route loaded/imported, signaling the map to frame it.
    private(set) var mapFitToken = 0

    @ObservationIgnored private var tickTask: Task<Void, Never>?

    init(
        simctl: SimctlService = SimctlService(),
        routeBuilder: RouteBuilder = RouteBuilder(),
        playback: PlaybackEngine? = nil,
        search: LocationSearchService? = nil
    ) {
        self.simctl = simctl
        self.routeBuilder = routeBuilder
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
