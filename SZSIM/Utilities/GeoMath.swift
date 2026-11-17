//
//  GeoMath.swift
//  SZSIM
//

import Foundation

/// Pure spherical geometry, no MapKit and no I/O — shared by `RouteSampler`
/// and `PlaybackEngine`, and fully testable.
enum GeoMath {
    private static let earthRadius = 6_371_000.0

    /// Distance in meters between two coordinates (haversine).
    static func distance(from a: RouteCoordinate, to b: RouteCoordinate) -> Double {
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadius * asin(min(1, sqrt(h)))
    }

    /// Initial bearing in degrees, 0 = North, clockwise.
    static func heading(from a: RouteCoordinate, to b: RouteCoordinate) -> Double {
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let degrees = atan2(y, x) * 180 / .pi
        return (degrees + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Linear interpolation in lat/lon (suitable for short steps).
    static func interpolate(from a: RouteCoordinate, to b: RouteCoordinate, fraction: Double) -> RouteCoordinate {
        RouteCoordinate(
            latitude: a.latitude + (b.latitude - a.latitude) * fraction,
            longitude: a.longitude + (b.longitude - a.longitude) * fraction
        )
    }

    /// Cumulative distances from the start to each vertex (the first is always 0).
    static func cumulativeDistances(_ polyline: [RouteCoordinate]) -> [Double] {
        guard !polyline.isEmpty else { return [] }
        var result = [0.0]
        for index in 1..<polyline.count {
            result.append(result[index - 1] + distance(from: polyline[index - 1], to: polyline[index]))
        }
        return result
    }

    /// Coordinate and heading at the arc length `distanceAlong` (meters).
    ///
    /// `distanceAlong` is clamped to `[0, total]`. Returns `nil` only for an empty polyline.
    static func point(
        atDistance distanceAlong: Double,
        polyline: [RouteCoordinate],
        cumulative: [Double]
    ) -> (coordinate: RouteCoordinate, heading: Double)? {
        guard polyline.count > 1, cumulative.count == polyline.count else {
            return polyline.first.map { ($0, 0) }
        }
        let total = cumulative.last ?? 0
        let clamped = max(0, min(distanceAlong, total))

        var index = 0
        while index < polyline.count - 2 && cumulative[index + 1] < clamped {
            index += 1
        }

        let segmentStart = cumulative[index]
        let segmentLength = cumulative[index + 1] - segmentStart
        let fraction = segmentLength > 0 ? (clamped - segmentStart) / segmentLength : 0
        let coordinate = interpolate(from: polyline[index], to: polyline[index + 1], fraction: fraction)
        let bearing = heading(from: polyline[index], to: polyline[index + 1])
        return (coordinate, bearing)
    }
}
