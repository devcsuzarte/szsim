//
//  MainViewModelTests.swift
//  SZSIMTests
//

import CoreLocation
import Testing
@testable import SZSIM

@MainActor
struct MainViewModelTests {
    private func bootedDevice(_ udid: String = "UDID-1") -> SimulatorDevice {
        SimulatorDevice(udid: udid, name: "iPhone 16 Pro", state: .booted, runtime: "iOS 18.2", isAvailable: true)
    }

    private func straightRouteViewModel(runner: RecordingSimctlRunner? = nil) async -> MainViewModel {
        let viewModel = MainViewModel(simctl: SimctlService(runner: runner ?? RecordingSimctlRunner()))
        viewModel.mode = .straight
        viewModel.addWaypoint(CLLocationCoordinate2D(latitude: 0, longitude: 0))
        viewModel.addWaypoint(CLLocationCoordinate2D(latitude: 0, longitude: 1))
        await viewModel.rebuildRoute()
        return viewModel
    }

    @Test func addWaypointLabelsOriginStopDestination() {
        let viewModel = MainViewModel()
        viewModel.addWaypoint(CLLocationCoordinate2D(latitude: 0, longitude: 0))
        #expect(viewModel.waypoints.map(\.kind) == [.origin])
        viewModel.addWaypoint(CLLocationCoordinate2D(latitude: 0, longitude: 1))
        #expect(viewModel.waypoints.map(\.kind) == [.origin, .destination])
        viewModel.addWaypoint(CLLocationCoordinate2D(latitude: 0, longitude: 2))
        #expect(viewModel.waypoints.map(\.kind) == [.origin, .stop, .destination])
    }

    @Test func removeWaypointRelabels() {
        let viewModel = MainViewModel()
        viewModel.addWaypoint(CLLocationCoordinate2D(latitude: 0, longitude: 0))
        viewModel.addWaypoint(CLLocationCoordinate2D(latitude: 0, longitude: 1))
        viewModel.addWaypoint(CLLocationCoordinate2D(latitude: 0, longitude: 2))
        let middle = viewModel.waypoints[1].id
        viewModel.removeWaypoint(id: middle)
        #expect(viewModel.waypoints.map(\.kind) == [.origin, .destination])
    }

    @Test func rebuildRouteStraightSetsPolylineAndLoadsPlayback() async {
        let viewModel = await straightRouteViewModel()
        #expect(viewModel.polyline.count == 2)
        #expect(abs(viewModel.distanceMeters - 111_195) < 100)
        #expect(viewModel.playback.totalDistance > 0)
    }

    @Test func advanceAndSendPushesCoordinateToSelectedDevice() async {
        let runner = RecordingSimctlRunner()
        let viewModel = await straightRouteViewModel(runner: runner)
        viewModel.devices = [bootedDevice("UDID-1")]
        viewModel.selectedDeviceID = "UDID-1"
        viewModel.playback.play()

        await viewModel.advanceAndSend()

        #expect(runner.calls.count == 1)
        #expect(runner.calls.first?.first == "location")
        #expect(runner.calls.first?[1] == "UDID-1")
        #expect(runner.calls.first?[2] == "set")
    }

    @Test func advanceAndSendWithoutDeviceSendsNothing() async {
        let runner = RecordingSimctlRunner()
        let viewModel = await straightRouteViewModel(runner: runner)
        viewModel.playback.play()

        await viewModel.advanceAndSend()

        #expect(runner.calls.isEmpty)
    }

    @Test func loadRestoresStateFromCachedRoute() {
        let viewModel = MainViewModel()
        let route = SavedRoute(
            name: "Paulista",
            waypoints: [
                Waypoint(latitude: 0, longitude: 0, kind: .origin),
                Waypoint(latitude: 0, longitude: 1, kind: .destination),
            ],
            mode: .straight,
            profile: .cycling,
            speed: .double,
            polyline: [
                RouteCoordinate(latitude: 0, longitude: 0),
                RouteCoordinate(latitude: 0, longitude: 1),
            ],
            distanceMeters: 111_195
        )

        viewModel.load(route)

        #expect(viewModel.waypoints.count == 2)
        #expect(viewModel.mode == .straight)
        #expect(viewModel.playback.profile == .cycling)
        #expect(viewModel.playback.speed == .double)
        #expect(viewModel.polyline.count == 2)
        #expect(abs(viewModel.distanceMeters - 111_195) < 1)
        #expect(viewModel.playback.totalDistance > 0)
        #expect(viewModel.mapFitToken == 1)
    }

    @Test func importPolylineSetsRouteAndEndpoints() {
        let viewModel = MainViewModel()
        viewModel.importPolyline([
            RouteCoordinate(latitude: 0, longitude: 0),
            RouteCoordinate(latitude: 0, longitude: 0.5),
            RouteCoordinate(latitude: 0, longitude: 1),
        ])
        #expect(viewModel.polyline.count == 3)
        #expect(viewModel.waypoints.count == 2)
        #expect(viewModel.waypoints.first?.kind == .origin)
        #expect(viewModel.waypoints.last?.kind == .destination)
        #expect(viewModel.mode == .straight)
        #expect(viewModel.playback.totalDistance > 0)
        #expect(viewModel.mapFitToken == 1)
    }

    @Test func canPlayRequiresDeviceAndRoute() async {
        let viewModel = MainViewModel()
        #expect(viewModel.canPlay == false)
        viewModel.devices = [bootedDevice()]
        viewModel.selectedDeviceID = "UDID-1"
        #expect(viewModel.canPlay == false)
        viewModel.mode = .straight
        viewModel.addWaypoint(CLLocationCoordinate2D(latitude: 0, longitude: 0))
        viewModel.addWaypoint(CLLocationCoordinate2D(latitude: 0, longitude: 1))
        await viewModel.rebuildRoute()
        #expect(viewModel.canPlay == true)
    }
}
