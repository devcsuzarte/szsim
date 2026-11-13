//
//  SavedRoutesViewModel.swift
//  SZSIM
//

import Foundation
import Observation
import SwiftData

/// Typed errors for route persistence.
enum StorageError: Error, Equatable {
    case nameExists
}

/// Lists, searches, and applies CRUD to saved routes (SwiftData).
@MainActor
@Observable
final class SavedRoutesViewModel {
    var searchText: String = ""
    private(set) var routes: [SavedRoute] = []

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        reload()
    }

    /// Routes filtered by the search text (by name).
    var filteredRoutes: [SavedRoute] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return routes }
        return routes.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func reload() {
        let descriptor = FetchDescriptor<SavedRoute>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        routes = (try? context.fetch(descriptor)) ?? []
    }

    /// An existing route with the same name (case-insensitive), if any.
    func existingRoute(named name: String) -> SavedRoute? {
        routes.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// Saves (or overwrites) a route. Throws `StorageError.nameExists` if the name
    /// already exists and `overwrite` is `false`.
    func save(
        name: String,
        waypoints: [Waypoint],
        mode: RouteMode,
        profile: MovementProfile,
        speed: PlaybackSpeed,
        polyline: [RouteCoordinate],
        distanceMeters: Double,
        overwrite: Bool
    ) throws {
        if let existing = existingRoute(named: name) {
            guard overwrite else { throw StorageError.nameExists }
            existing.waypoints = waypoints
            existing.mode = mode
            existing.profile = profile
            existing.speed = speed
            existing.polyline = polyline
            existing.distanceMeters = distanceMeters
            existing.updatedAt = .now
        } else {
            context.insert(SavedRoute(
                name: name,
                waypoints: waypoints,
                mode: mode,
                profile: profile,
                speed: speed,
                polyline: polyline,
                distanceMeters: distanceMeters
            ))
        }
        try context.save()
        reload()
    }

    func delete(_ route: SavedRoute) throws {
        context.delete(route)
        try context.save()
        reload()
    }
}
