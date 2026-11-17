//
//  PointSendTests.swift
//  SZSIMTests
//

import CoreLocation
import Testing
@testable import SZSIM

/// `ReverseGeocoding` stub that never hits the network.
struct StubGeocoder: ReverseGeocoding {
    var result: String?
    func address(for coordinate: CLLocationCoordinate2D) async -> String? { result }
}

@MainActor
struct PointSendTests {
    private func makeViewModel(_ runner: RecordingSimctlRunner) -> MainViewModel {
        let viewModel = MainViewModel(
            simctl: SimctlService(runner: runner),
            geocoder: StubGeocoder(result: nil)
        )
        viewModel.devices = [
            SimulatorDevice(udid: "UDID-1", name: "iPhone 15", state: .booted, runtime: "iOS 18.0", isAvailable: true)
        ]
        viewModel.selectedDeviceID = viewModel.devices.first?.id
        return viewModel
    }

    @Test func setSelectedPointSendsToSelectedUDID() async {
        let runner = RecordingSimctlRunner()
        let viewModel = makeViewModel(runner)

        viewModel.selectPoint(CLLocationCoordinate2D(latitude: -23.5, longitude: -46.6))
        await viewModel.setSelectedPointOnSimulator()

        #expect(runner.calls == [["location", "UDID-1", "set", "-23.5,-46.6"]])
        #expect(viewModel.selectedPoint?.lastSend?.deviceName == "iPhone 15")
    }

    @Test func setSelectedPointDoesNothingWithoutSelection() async {
        let runner = RecordingSimctlRunner()
        let viewModel = makeViewModel(runner)

        await viewModel.setSelectedPointOnSimulator()

        #expect(runner.calls.isEmpty)
    }

    @Test func sendSavedPointUsesSelectedUDID() async {
        let runner = RecordingSimctlRunner()
        let viewModel = makeViewModel(runner)
        let point = SavedPoint(name: "Home", latitude: 1.25, longitude: 2.5)

        let sent = await viewModel.sendSavedPoint(point)

        #expect(sent)
        #expect(runner.calls == [["location", "UDID-1", "set", "1.25,2.5"]])
    }
}
