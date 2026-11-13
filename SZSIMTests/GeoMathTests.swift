//
//  GeoMathTests.swift
//  SZSIMTests
//

import Testing
@testable import SZSIM

struct GeoMathTests {
    @Test func distanceAlongMeridianMatchesDegreeLength() {
        let distance = GeoMath.distance(
            from: RouteCoordinate(latitude: 0, longitude: 0),
            to: RouteCoordinate(latitude: 1, longitude: 0)
        )
        // Um grau de latitude ≈ 111,2 km.
        #expect(abs(distance - 111_195) < 100)
    }

    @Test func headingEastIsNinety() {
        let heading = GeoMath.heading(
            from: RouteCoordinate(latitude: 0, longitude: 0),
            to: RouteCoordinate(latitude: 0, longitude: 1)
        )
        #expect(abs(heading - 90) < 0.5)
    }

    @Test func headingNorthIsZero() {
        let heading = GeoMath.heading(
            from: RouteCoordinate(latitude: 0, longitude: 0),
            to: RouteCoordinate(latitude: 1, longitude: 0)
        )
        #expect(abs(heading - 0) < 0.5)
    }

    @Test func headingWestIsTwoSeventy() {
        let heading = GeoMath.heading(
            from: RouteCoordinate(latitude: 0, longitude: 0),
            to: RouteCoordinate(latitude: 0, longitude: -1)
        )
        #expect(abs(heading - 270) < 0.5)
    }

    @Test func cumulativeDistancesAreMonotonic() {
        let line = [
            RouteCoordinate(latitude: 0, longitude: 0),
            RouteCoordinate(latitude: 0, longitude: 1),
            RouteCoordinate(latitude: 1, longitude: 1),
        ]
        let cumulative = GeoMath.cumulativeDistances(line)
        #expect(cumulative.count == 3)
        #expect(cumulative[0] == 0)
        #expect(cumulative[1] < cumulative[2])
    }
}
