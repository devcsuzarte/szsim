//
//  SavedRoute.swift
//  SZSIM
//

import Foundation
import SwiftData

/// A route saved by the user, persisted via SwiftData.
///
/// The `polyline` is cached so that loading the route redraws the trip without
/// calling `MKDirections` again — we only recompute if the points change.
@Model
final class SavedRoute {
    var id: UUID
    var name: String
    var waypoints: [Waypoint]
    var mode: RouteMode
    var profile: MovementProfile
    var speed: PlaybackSpeed
    var polyline: [RouteCoordinate]
    var distanceMeters: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        waypoints: [Waypoint],
        mode: RouteMode,
        profile: MovementProfile,
        speed: PlaybackSpeed,
        polyline: [RouteCoordinate],
        distanceMeters: Double,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.waypoints = waypoints
        self.mode = mode
        self.profile = profile
        self.speed = speed
        self.polyline = polyline
        self.distanceMeters = distanceMeters
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
