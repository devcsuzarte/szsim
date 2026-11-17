//
//  MovementProfile.swift
//  SZSIM
//

import Foundation

/// Movement profile that defines the base playback speed.
enum MovementProfile: String, CaseIterable, Codable, Sendable, Identifiable {
    case walking
    case cycling
    case driving

    var id: String { rawValue }

    /// Base speed in meters per second.
    var speedMetersPerSecond: Double {
        switch self {
        case .walking: 1.4
        case .cycling: 5.5
        case .driving: 13.9
        }
    }
}
