//
//  SimctlService.swift
//  SZSIM
//

import CoreLocation
import Foundation
import os

/// Typed errors for `simctl` operations.
enum SimctlError: Error, Equatable {
    case launchFailed(String)
    case commandFailed(code: Int32, stderr: String)
}

/// Abstraction over running `xcrun simctl`, to allow mocking in tests.
protocol SimctlRunning {
    /// Runs `xcrun simctl <arguments...>` and returns standard output.
    func runSimctl(_ arguments: [String]) async throws -> Data
}

/// Builds and runs `simctl` commands, always using the selected UDID.
struct SimctlService {
    private let runner: any SimctlRunning

    init(runner: any SimctlRunning = SimctlRunner()) {
        self.runner = runner
    }

    /// Lists simulators with `Booted` status.
    func bootedDevices() async throws -> [SimulatorDevice] {
        let data = try await runner.runSimctl(["list", "devices", "booted", "-j"])
        return try SimulatorDevice.devices(fromListJSON: data)
    }

    /// Sends a coordinate to the simulator identified by `udid`.
    func setLocation(udid: String, coordinate: CLLocationCoordinate2D) async throws {
        let argument = "\(coordinate.latitude),\(coordinate.longitude)"
        _ = try await runner.runSimctl(["location", udid, "set", argument])
    }

    /// Clears the device's simulated location (explicit user action).
    func clearLocation(udid: String) async throws {
        _ = try await runner.runSimctl(["location", udid, "clear"])
    }
}

/// Real implementation that runs `/usr/bin/xcrun` off the main thread.
struct SimctlRunner: SimctlRunning {
    private static let logger = Logger(subsystem: "com.szsim.app", category: "simctl")

    func runSimctl(_ arguments: [String]) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            process.arguments = ["simctl"] + arguments

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            do {
                try process.run()
            } catch {
                Self.logger.error("Failed to launch simctl: \(error.localizedDescription)")
                throw SimctlError.launchFailed(error.localizedDescription)
            }

            // simctl writes little to stderr, so reading stdout to EOF doesn't deadlock.
            let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
            let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                let message = String(decoding: errorData, as: UTF8.self)
                Self.logger.error("simctl \(arguments.joined(separator: " ")) failed (\(process.terminationStatus)): \(message)")
                throw SimctlError.commandFailed(code: process.terminationStatus, stderr: message)
            }
            return outputData
        }.value
    }
}
