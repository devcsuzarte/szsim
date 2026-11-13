//
//  RouteMode.swift
//  SZSIM
//

import Foundation

/// How the route is traced between waypoints.
enum RouteMode: String, CaseIterable, Codable, Sendable, Identifiable {
    /// Follows the streets using `MKDirections`.
    case streets
    /// Connects the points with geodesic segments (straight line).
    case straight

    var id: String { rawValue }
}
