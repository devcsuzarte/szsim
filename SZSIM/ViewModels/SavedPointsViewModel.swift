//
//  SavedPointsViewModel.swift
//  SZSIM
//

import Foundation
import Observation
import SwiftData

/// Lists, searches, and applies CRUD to saved points (SwiftData).
///
/// Ordered by `lastUsedAt` (most recent first). Shares `StorageError` with
/// `SavedRoutesViewModel`.
@MainActor
@Observable
final class SavedPointsViewModel {
    var searchText: String = ""
    private(set) var points: [SavedPoint] = []

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        reload()
    }

    /// Points filtered by the search text (by name or address).
    var filteredPoints: [SavedPoint] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return points }
        return points.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || ($0.address?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    func reload() {
        let descriptor = FetchDescriptor<SavedPoint>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        points = (try? context.fetch(descriptor)) ?? []
    }

    /// An existing point with the same name (case-insensitive), if any.
    func existingPoint(named name: String) -> SavedPoint? {
        points.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// Saves (or overwrites) a point. Throws `StorageError.nameExists` if the name
    /// already exists and `overwrite` is `false`.
    func save(
        name: String,
        coordinate: RouteCoordinate,
        address: String?,
        overwrite: Bool
    ) throws {
        if let existing = existingPoint(named: name) {
            guard overwrite else { throw StorageError.nameExists }
            existing.latitude = coordinate.latitude
            existing.longitude = coordinate.longitude
            existing.address = address
            existing.updatedAt = .now
        } else {
            context.insert(SavedPoint(
                name: name,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                address: address
            ))
        }
        try context.save()
        reload()
    }

    /// Marks a point as just used, moving it to the top of the list.
    func touch(_ point: SavedPoint) throws {
        point.lastUsedAt = .now
        try context.save()
        reload()
    }

    func delete(_ point: SavedPoint) throws {
        context.delete(point)
        try context.save()
        reload()
    }
}
