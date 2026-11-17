//
//  DomainModelTests.swift
//  SZSIMTests
//

import CoreLocation
import Testing
@testable import SZSIM

struct MovementProfileTests {
    @Test func hasExpectedSpeeds() {
        #expect(MovementProfile.walking.speedMetersPerSecond == 1.4)
        #expect(MovementProfile.cycling.speedMetersPerSecond == 5.5)
        #expect(MovementProfile.driving.speedMetersPerSecond == 13.9)
    }

    @Test func coversThreeProfiles() {
        #expect(MovementProfile.allCases.count == 3)
    }
}

struct PlaybackSpeedTests {
    @Test func hasFiveSpeeds() {
        #expect(PlaybackSpeed.allCases.count == 5)
    }

    @Test func multiplierMatchesRawValue() {
        #expect(PlaybackSpeed.half.multiplier == 0.5)
        #expect(PlaybackSpeed.normal.multiplier == 1)
        #expect(PlaybackSpeed.veryFast.multiplier == 10)
    }
}

struct RouteModeTests {
    @Test func hasStreetsAndStraight() {
        #expect(RouteMode.allCases.count == 2)
        #expect(RouteMode.allCases.contains(.streets))
        #expect(RouteMode.allCases.contains(.straight))
    }
}

struct WaypointTests {
    @Test func exposesCoordinateFromLatLon() {
        let waypoint = Waypoint(latitude: -23.55959, longitude: -46.63339, kind: .origin)
        #expect(waypoint.coordinate.latitude == -23.55959)
        #expect(waypoint.coordinate.longitude == -46.63339)
        #expect(waypoint.kind == .origin)
    }

    @Test func initsFromCoordinate() {
        let coordinate = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        let waypoint = Waypoint(coordinate: coordinate, kind: .destination)
        #expect(waypoint.latitude == 1)
        #expect(waypoint.longitude == 2)
        #expect(waypoint.kind == .destination)
    }
}
