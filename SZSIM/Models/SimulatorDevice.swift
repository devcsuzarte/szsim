//
//  SimulatorDevice.swift
//  SZSIM
//

import Foundation

/// An iOS simulator, decoded from the JSON of `xcrun simctl list devices -j`.
struct SimulatorDevice: Identifiable, Hashable, Sendable {
    let udid: String
    let name: String
    let state: State
    /// Human-readable runtime name, e.g. "iOS 26.5".
    let runtime: String
    let isAvailable: Bool

    var id: String { udid }
    var isBooted: Bool { state == .booted }

    /// The simulator state as reported by `simctl`.
    enum State: String, Sendable {
        case booted = "Booted"
        case booting = "Booting"
        case shuttingDown = "Shutting Down"
        case shutdown = "Shutdown"
        case creating = "Creating"
        case unknown
    }
}

extension SimulatorDevice {
    private struct DeviceList: Decodable {
        let devices: [String: [RawDevice]]
    }

    private struct RawDevice: Decodable {
        let udid: String
        let name: String
        let state: String
        let isAvailable: Bool
    }

    /// Decodes the device list from the `simctl` JSON output.
    ///
    /// The key of the `devices` dictionary is the runtime identifier; the
    /// human-readable name is derived from it and applied to every device of that runtime.
    static func devices(fromListJSON data: Data) throws -> [SimulatorDevice] {
        let list = try JSONDecoder().decode(DeviceList.self, from: data)
        return list.devices.flatMap { key, rawDevices in
            let runtime = runtimeName(fromKey: key)
            return rawDevices.map { raw in
                SimulatorDevice(
                    udid: raw.udid,
                    name: raw.name,
                    state: State(rawValue: raw.state) ?? .unknown,
                    runtime: runtime,
                    isAvailable: raw.isAvailable
                )
            }
        }
    }

    /// Converts "com.apple.CoreSimulator.SimRuntime.iOS-26-5" into "iOS 26.5".
    static func runtimeName(fromKey key: String) -> String {
        guard let last = key.split(separator: ".").last else { return key }
        let parts = last.split(separator: "-")
        guard parts.count >= 2 else { return String(last) }
        let os = parts[0]
        let version = parts.dropFirst().joined(separator: ".")
        return "\(os) \(version)"
    }
}
