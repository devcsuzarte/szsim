//
//  RouteSamplerTests.swift
//  SZSIMTests
//

import Testing
@testable import SZSIM

struct RouteSamplerTests {
    private let sampler = RouteSampler()
    // Straight line along the equator: (0,0) -> (0,1) ≈ 111,195 m.
    private let eastLine = [
        RouteCoordinate(latitude: 0, longitude: 0),
        RouteCoordinate(latitude: 0, longitude: 1),
    ]

    @Test func emptyPolylineProducesNoSamples() {
        #expect(sampler.sample(polyline: [], speedMetersPerSecond: 10, interval: 1).isEmpty)
    }

    @Test func singlePointProducesOneSample() {
        let samples = sampler.sample(
            polyline: [RouteCoordinate(latitude: 1, longitude: 2)],
            speedMetersPerSecond: 10,
            interval: 1
        )
        #expect(samples.count == 1)
        #expect(samples.first?.coordinate == RouteCoordinate(latitude: 1, longitude: 2))
    }

    @Test func samplesStartAtOriginEndAtDestination() {
        let samples = sampler.sample(polyline: eastLine, speedMetersPerSecond: 11_119.5, interval: 1)
        #expect(samples.count >= 2)
        #expect(approxEqual(samples.first!.coordinate, eastLine.first!))
        #expect(approxEqual(samples.last!.coordinate, eastLine.last!))
    }

    @Test func headingsAlongEastLineAreNinety() {
        let samples = sampler.sample(polyline: eastLine, speedMetersPerSecond: 11_119.5, interval: 1)
        for sample in samples {
            #expect(abs(sample.heading - 90) < 1)
        }
    }

    @Test func spacingMatchesStep() {
        let step = 11_119.5
        let samples = sampler.sample(polyline: eastLine, speedMetersPerSecond: step, interval: 1)
        #expect(samples.count >= 3)
        let gap = GeoMath.distance(from: samples[0].coordinate, to: samples[1].coordinate)
        #expect(abs(gap - step) < step * 0.05)
    }
}
