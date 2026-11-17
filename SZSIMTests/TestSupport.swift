//
//  TestSupport.swift
//  SZSIMTests
//

import Foundation
@testable import SZSIM

/// Compares coordinates with tolerance (avoids comparing Double for exact equality).
func approxEqual(_ a: RouteCoordinate, _ b: RouteCoordinate, tolerance: Double = 1e-6) -> Bool {
    abs(a.latitude - b.latitude) < tolerance && abs(a.longitude - b.longitude) < tolerance
}

/// `SimctlRunning` stub that records the arguments without running `xcrun`.
@MainActor
final class RecordingSimctlRunner: SimctlRunning {
    var output = Data()
    var calls: [[String]] = []
    var error: (any Error)?

    func runSimctl(_ arguments: [String]) async throws -> Data {
        calls.append(arguments)
        if let error { throw error }
        return output
    }
}
