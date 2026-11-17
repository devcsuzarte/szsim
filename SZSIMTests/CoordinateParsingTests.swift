//
//  CoordinateParsingTests.swift
//  SZSIMTests
//

import CoreLocation
import Testing
@testable import SZSIM

struct CoordinateParsingTests {
    @Test func parsesCommaSeparatedLatLon() throws {
        let coordinate = try #require(CoordinateParser.parse("-23.5505, -46.6333"))
        #expect(abs(coordinate.latitude - (-23.5505)) < 1e-9)
        #expect(abs(coordinate.longitude - (-46.6333)) < 1e-9)
    }

    @Test func parsesWithoutSpace() {
        #expect(CoordinateParser.parse("10,20") != nil)
    }

    @Test func rejectsAddressText() {
        #expect(CoordinateParser.parse("Av. Paulista") == nil)
    }

    @Test func rejectsOutOfRangeValues() {
        #expect(CoordinateParser.parse("100, 200") == nil)
        #expect(CoordinateParser.parse("10") == nil)
    }
}
