//
//  RouteSampler.swift
//  SZSIM
//

import Foundation

/// A resampled polyline point: coordinate + segment heading.
struct RouteSample: Equatable, Sendable {
    var coordinate: RouteCoordinate
    var heading: Double
}

/// Resamples a polyline into points evenly spaced by the playback speed.
/// Pure logic, no MapKit and no I/O.
struct RouteSampler {
    /// Generates samples every `speedMetersPerSecond × interval` meters along the
    /// polyline, always including origin and destination.
    func sample(
        polyline: [RouteCoordinate],
        speedMetersPerSecond: Double,
        interval: TimeInterval
    ) -> [RouteSample] {
        guard polyline.count > 1 else {
            return polyline.first.map { [RouteSample(coordinate: $0, heading: 0)] } ?? []
        }

        let cumulative = GeoMath.cumulativeDistances(polyline)
        let total = cumulative.last ?? 0
        let step = speedMetersPerSecond * interval

        guard step > 0, total > 0 else {
            return GeoMath.point(atDistance: 0, polyline: polyline, cumulative: cumulative)
                .map { [RouteSample(coordinate: $0.coordinate, heading: $0.heading)] } ?? []
        }

        var samples: [RouteSample] = []
        var distanceAlong = 0.0
        while distanceAlong < total {
            if let point = GeoMath.point(atDistance: distanceAlong, polyline: polyline, cumulative: cumulative) {
                samples.append(RouteSample(coordinate: point.coordinate, heading: point.heading))
            }
            distanceAlong += step
        }

        if let end = GeoMath.point(atDistance: total, polyline: polyline, cumulative: cumulative) {
            samples.append(RouteSample(coordinate: end.coordinate, heading: end.heading))
        }
        return samples
    }
}
