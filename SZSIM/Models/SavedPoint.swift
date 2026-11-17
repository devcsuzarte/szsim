//
//  SavedPoint.swift
//  SZSIM
//

import CoreLocation
import Foundation
import SwiftData

/// A fixed location saved by the user, persisted via SwiftData.
///
/// Unlike `SavedRoute`, a point is a single coordinate the user can set on the
/// simulator with one click. `lastUsedAt` drives the "most recent first" ordering.
@Model
final class SavedPoint {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var address: String?
    var createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        address: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastUsedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsedAt = lastUsedAt
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
