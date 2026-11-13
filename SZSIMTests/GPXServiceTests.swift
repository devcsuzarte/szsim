//
//  GPXServiceTests.swift
//  SZSIMTests
//

import Testing
@testable import SZSIM

struct GPXServiceTests {
    private let service = GPXService()
    private let polyline = [
        RouteCoordinate(latitude: -23.55959, longitude: -46.63339),
        RouteCoordinate(latitude: -23.56140, longitude: -46.65599),
    ]

    @Test func exportImportRoundTripPreservesCoordinates() throws {
        let gpx = service.export(polyline: polyline, profile: .driving, name: "Teste")
        let imported = try service.importRoute(from: gpx)
        #expect(imported.count == 2)
        #expect(approxEqual(imported[0], polyline[0], tolerance: 1e-5))
        #expect(approxEqual(imported[1], polyline[1], tolerance: 1e-5))
    }

    @Test func exportIncludesTimeTags() {
        let gpx = service.export(polyline: polyline, profile: .driving, name: "Teste")
        #expect(gpx.contains("<trkpt"))
        #expect(gpx.contains("<time>"))
    }

    @Test func importParsesKMLCoordinates() throws {
        let kml = """
        <kml><Placemark><LineString><coordinates>
        -46.63339,-23.55959,0 -46.65599,-23.56140,0
        </coordinates></LineString></Placemark></kml>
        """
        let imported = try service.importRoute(from: kml)
        #expect(imported.count == 2)
        #expect(approxEqual(imported[0], RouteCoordinate(latitude: -23.55959, longitude: -46.63339), tolerance: 1e-5))
        #expect(approxEqual(imported[1], RouteCoordinate(latitude: -23.56140, longitude: -46.65599), tolerance: 1e-5))
    }

    @Test func importParsesWaypointsWithoutTime() throws {
        let gpx = """
        <gpx><wpt lat="1.5" lon="2.5"></wpt><wpt lat="3.5" lon="4.5"></wpt></gpx>
        """
        let imported = try service.importRoute(from: gpx)
        #expect(imported.count == 2)
        #expect(approxEqual(imported[0], RouteCoordinate(latitude: 1.5, longitude: 2.5)))
    }

    @Test func importRejectsEmpty() {
        #expect(throws: GPXError.self) {
            _ = try service.importRoute(from: "   ")
        }
    }

    @Test func importRejectsGarbage() {
        #expect(throws: GPXError.self) {
            _ = try service.importRoute(from: "<html><body>nada aqui</body></html>")
        }
    }
}
