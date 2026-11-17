//
//  SimulatorDeviceTests.swift
//  SZSIMTests
//

import Foundation
import Testing
@testable import SZSIM

struct SimulatorDeviceTests {
    // Real output of `xcrun simctl list devices booted -j` on this Mac.
    static let listJSON = """
    {"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-26-5":[{"udid":"FFD9758E-30F7-475C-ACDF-B82623BA4232","name":"iPhone 12","state":"Booted","isAvailable":true,"deviceTypeIdentifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-12"}]}}
    """

    @Test func decodesBootedDeviceFromListJSON() throws {
        let devices = try SimulatorDevice.devices(fromListJSON: Data(Self.listJSON.utf8))
        #expect(devices.count == 1)
        let device = try #require(devices.first)
        #expect(device.udid == "FFD9758E-30F7-475C-ACDF-B82623BA4232")
        #expect(device.name == "iPhone 12")
        #expect(device.state == .booted)
        #expect(device.isBooted)
        #expect(device.runtime == "iOS 26.5")
        #expect(device.isAvailable)
    }

    @Test func parsesRuntimeNameFromKey() {
        let key = "com.apple.CoreSimulator.SimRuntime.iOS-18-2"
        #expect(SimulatorDevice.runtimeName(fromKey: key) == "iOS 18.2")
    }

    @Test func mapsUnrecognizedStateToUnknown() throws {
        let json = #"{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-18-2":[{"udid":"X","name":"iPhone 16 Pro","state":"Weird","isAvailable":true}]}}"#
        let devices = try SimulatorDevice.devices(fromListJSON: Data(json.utf8))
        #expect(devices.first?.state == .unknown)
        #expect(devices.first?.isBooted == false)
    }
}
