//
//  RouteBuilderTests.swift
//  SZSIMTests
//

import Testing
@testable import SZSIM

@MainActor
struct RouteBuilderTests {
    /// Stub that always returns the same result.
    struct StubDirections: DirectionsProviding {
        var result: Result<BuiltRoute, any Error>
        func route(from: RouteCoordinate, to: RouteCoordinate, transport: MovementProfile) async throws -> BuiltRoute {
            try result.get()
        }
    }

    /// Stub that echoes a straight segment [from, to] with the geodesic distance.
    struct EchoDirections: DirectionsProviding {
        func route(from: RouteCoordinate, to: RouteCoordinate, transport: MovementProfile) async throws -> BuiltRoute {
            BuiltRoute(polyline: [from, to], distanceMeters: GeoMath.distance(from: from, to: to))
        }
    }

    private func waypoint(_ lat: Double, _ lon: Double, _ kind: Waypoint.Kind) -> Waypoint {
        Waypoint(latitude: lat, longitude: lon, kind: kind)
    }

    @Test func throwsWithFewerThanTwoWaypoints() async {
        let builder = RouteBuilder(directions: StubDirections(result: .success(BuiltRoute(polyline: [], distanceMeters: 0))))
        await #expect(throws: RouteBuildError.self) {
            _ = try await builder.build(
                waypoints: [waypoint(0, 0, .origin)],
                mode: .streets,
                profile: .driving
            )
        }
    }

    @Test func straightModeUsesWaypointsAndGeodesicDistance() async throws {
        let builder = RouteBuilder(directions: StubDirections(result: .failure(RouteBuildError.noRoute)))
        let route = try await builder.build(
            waypoints: [waypoint(0, 0, .origin), waypoint(0, 1, .destination)],
            mode: .straight,
            profile: .driving
        )
        #expect(route.polyline.count == 2)
        #expect(approxEqual(route.polyline.first!, RouteCoordinate(latitude: 0, longitude: 0)))
        #expect(approxEqual(route.polyline.last!, RouteCoordinate(latitude: 0, longitude: 1)))
        #expect(abs(route.distanceMeters - 111_195) < 100)
    }

    @Test func streetsModeConcatenatesSegmentsWithoutDuplicatingJoins() async throws {
        let builder = RouteBuilder(directions: EchoDirections())
        let route = try await builder.build(
            waypoints: [waypoint(0, 0, .origin), waypoint(0, 1, .stop), waypoint(0, 2, .destination)],
            mode: .streets,
            profile: .driving
        )
        #expect(route.polyline.count == 3)
        #expect(approxEqual(route.polyline[0], RouteCoordinate(latitude: 0, longitude: 0)))
        #expect(approxEqual(route.polyline[1], RouteCoordinate(latitude: 0, longitude: 1)))
        #expect(approxEqual(route.polyline[2], RouteCoordinate(latitude: 0, longitude: 2)))
    }

    @Test func streetsModeSurfacesDirectionsError() async {
        let builder = RouteBuilder(directions: StubDirections(result: .failure(RouteBuildError.noRoute)))
        await #expect(throws: RouteBuildError.self) {
            _ = try await builder.build(
                waypoints: [waypoint(0, 0, .origin), waypoint(0, 1, .destination)],
                mode: .streets,
                profile: .driving
            )
        }
    }
}
