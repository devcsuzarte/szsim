//
//  Waypoint.swift
//  SZSIM
//

import CoreLocation

/// A point marked on the map that makes up the trip.
///
/// The coordinate is stored as `latitude`/`longitude` (Double) so the type is
/// trivially `Hashable`, `Codable`, and `Sendable` — `CLLocationCoordinate2D`
/// does not provide those conformances.
struct Waypoint: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var latitude: Double
    var longitude: Double
    var kind: Kind

    /// The point's role in the trip.
    enum Kind: String, Codable, Sendable {
        case origin
        case stop
        case destination
    }

    init(id: UUID = UUID(), latitude: Double, longitude: Double, kind: Kind) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.kind = kind
    }

    init(id: UUID = UUID(), coordinate: CLLocationCoordinate2D, kind: Kind) {
        self.init(id: id, latitude: coordinate.latitude, longitude: coordinate.longitude, kind: kind)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
