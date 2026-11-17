//
//  RouteCoordinate.swift
//  SZSIM
//

import CoreLocation

/// A serializable coordinate used to cache polylines and route points.
///
/// Mirrors `CLLocationCoordinate2D` with conformances it does not provide
/// (`Codable`, `Hashable`, `Sendable`), enabling persistence via SwiftData.
struct RouteCoordinate: Codable, Hashable, Sendable {
    var latitude: Double
    var longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
