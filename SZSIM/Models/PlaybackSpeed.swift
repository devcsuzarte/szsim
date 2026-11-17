//
//  PlaybackSpeed.swift
//  SZSIM
//

import Foundation

/// Speed multiplier applied on top of the profile during playback.
enum PlaybackSpeed: Double, CaseIterable, Codable, Sendable, Identifiable {
    case half = 0.5
    case normal = 1
    case double = 2
    case fast = 5
    case veryFast = 10

    var id: Double { rawValue }

    /// The speed multiplier factor.
    var multiplier: Double { rawValue }
}
