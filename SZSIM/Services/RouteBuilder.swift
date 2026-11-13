//
//  RouteBuilder.swift
//  SZSIM
//

import MapKit

/// Typed errors for route building.
enum RouteBuildError: Error, Equatable {
    case insufficientWaypoints
    case noRoute
    case directionsFailed(String)
}

/// Build result: cached polyline + total distance.
struct BuiltRoute: Equatable, Sendable {
    var polyline: [RouteCoordinate]
    var distanceMeters: Double
}

/// Provides the street route between two points. Abstracts `MKDirections` for testing.
protocol DirectionsProviding {
    func route(from: RouteCoordinate, to: RouteCoordinate, transport: MovementProfile) async throws -> BuiltRoute
}

/// Builds the route by concatenating segments (streets mode) or connecting points
/// with a geodesic straight line (straight mode).
struct RouteBuilder {
    private let directions: any DirectionsProviding

    init(directions: any DirectionsProviding = MapKitDirectionsProvider()) {
        self.directions = directions
    }

    func build(waypoints: [Waypoint], mode: RouteMode, profile: MovementProfile) async throws -> BuiltRoute {
        guard waypoints.count >= 2 else { throw RouteBuildError.insufficientWaypoints }
        switch mode {
        case .straight: return straightRoute(waypoints)
        case .streets: return try await streetsRoute(waypoints, profile: profile)
        }
    }

    private func straightRoute(_ waypoints: [Waypoint]) -> BuiltRoute {
        let polyline = waypoints.map { RouteCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
        let distance = zip(polyline, polyline.dropFirst()).reduce(0) { total, pair in
            total + GeoMath.distance(from: pair.0, to: pair.1)
        }
        return BuiltRoute(polyline: polyline, distanceMeters: distance)
    }

    private func streetsRoute(_ waypoints: [Waypoint], profile: MovementProfile) async throws -> BuiltRoute {
        var polyline: [RouteCoordinate] = []
        var distance = 0.0

        for index in 1..<waypoints.count {
            let from = RouteCoordinate(latitude: waypoints[index - 1].latitude, longitude: waypoints[index - 1].longitude)
            let to = RouteCoordinate(latitude: waypoints[index].latitude, longitude: waypoints[index].longitude)

            let segment: BuiltRoute
            do {
                segment = try await directions.route(from: from, to: to, transport: profile)
            } catch let error as RouteBuildError {
                throw error
            } catch {
                throw RouteBuildError.directionsFailed(error.localizedDescription)
            }

            // Drops the duplicate join point between consecutive segments.
            polyline.append(contentsOf: polyline.isEmpty ? segment.polyline : Array(segment.polyline.dropFirst()))
            distance += segment.distanceMeters
        }
        return BuiltRoute(polyline: polyline, distanceMeters: distance)
    }
}

extension MovementProfile {
    /// MapKit transport type. Cycling is approximated by walking.
    var mapKitTransportType: MKDirectionsTransportType {
        switch self {
        case .walking, .cycling: .walking
        case .driving: .automobile
        }
    }
}

/// Real implementation based on `MKDirections`.
struct MapKitDirectionsProvider: DirectionsProviding {
    func route(from: RouteCoordinate, to: RouteCoordinate, transport: MovementProfile) async throws -> BuiltRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(location: CLLocation(latitude: from.latitude, longitude: from.longitude), address: nil)
        request.destination = MKMapItem(location: CLLocation(latitude: to.latitude, longitude: to.longitude), address: nil)
        request.transportType = transport.mapKitTransportType

        let response: MKDirections.Response
        do {
            response = try await MKDirections(request: request).calculate()
        } catch {
            throw RouteBuildError.directionsFailed(error.localizedDescription)
        }

        guard let route = response.routes.first else { throw RouteBuildError.noRoute }
        let polyline = route.polyline.coordinates.map(RouteCoordinate.init)
        return BuiltRoute(polyline: polyline, distanceMeters: route.distance)
    }
}
