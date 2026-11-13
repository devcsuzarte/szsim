//
//  SimctlServiceTests.swift
//  SZSIMTests
//

import CoreLocation
import Foundation
import Testing
@testable import SZSIM

@MainActor
struct SimctlServiceTests {
    /// Stub that records the arguments passed to `simctl`, without running anything.
    final class MockRunner: SimctlRunning {
        var output = Data()
        var calls: [[String]] = []
        var error: (any Error)?

        func runSimctl(_ arguments: [String]) async throws -> Data {
            calls.append(arguments)
            if let error { throw error }
            return output
        }
    }

    @Test func bootedDevicesRequestsListAndParses() async throws {
        let mock = MockRunner()
        mock.output = Data(SimulatorDeviceTests.listJSON.utf8)
        let service = SimctlService(runner: mock)

        let devices = try await service.bootedDevices()

        #expect(devices.count == 1)
        #expect(devices.first?.isBooted == true)
        #expect(mock.calls == [["list", "devices", "booted", "-j"]])
    }

    @Test func setLocationUsesUDIDNeverBooted() async throws {
        let mock = MockRunner()
        let service = SimctlService(runner: mock)
        let coordinate = CLLocationCoordinate2D(latitude: -23.55959, longitude: -46.63339)

        try await service.setLocation(udid: "ABC-123", coordinate: coordinate)

        #expect(mock.calls == [["location", "ABC-123", "set", "-23.55959,-46.63339"]])
        #expect(mock.calls.first?.contains("booted") == false)
    }

    @Test func clearLocationUsesUDID() async throws {
        let mock = MockRunner()
        let service = SimctlService(runner: mock)

        try await service.clearLocation(udid: "ABC-123")

        #expect(mock.calls == [["location", "ABC-123", "clear"]])
    }

    @Test func propagatesRunnerError() async {
        let mock = MockRunner()
        mock.error = SimctlError.commandFailed(code: 1, stderr: "boom")
        let service = SimctlService(runner: mock)

        await #expect(throws: SimctlError.self) {
            try await service.clearLocation(udid: "X")
        }
    }
}
