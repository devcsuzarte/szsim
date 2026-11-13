//
//  GPXService.swift
//  SZSIM
//

import Foundation

/// Typed errors for GPX import/export.
enum GPXError: Error, Equatable {
    case empty
    case invalidFormat
}

/// Exports and imports trips as GPX (and imports KML from other tools).
struct GPXService {
    /// Produces a GPX with `<trkpt>` + `<time>` computed from the profile speed at 1×.
    ///
    /// The per-point `<time>` lets the file be used in Xcode (Default Location) and
    /// on a physical device.
    func export(
        polyline: [RouteCoordinate],
        profile: MovementProfile,
        name: String,
        startDate: Date = Date()
    ) -> String {
        let cumulative = GeoMath.cumulativeDistances(polyline)
        let speed = profile.speedMetersPerSecond
        let formatter = ISO8601DateFormatter()

        let points = polyline.enumerated().map { index, coordinate -> String in
            let elapsed = speed > 0 ? cumulative[index] / speed : 0
            let time = formatter.string(from: startDate.addingTimeInterval(elapsed))
            return "    <trkpt lat=\"\(coordinate.latitude)\" lon=\"\(coordinate.longitude)\"><time>\(time)</time></trkpt>"
        }.joined(separator: "\n")

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="SZSIM" xmlns="http://www.topografix.com/GPX/1/1">
          <trk><name>\(name)</name><trkseg>
        \(points)
          </trkseg></trk>
        </gpx>
        """
    }

    /// Imports coordinates from a GPX (`<trkpt>`/`<wpt>`/`<rtept>`) or KML (`<coordinates>`).
    func importRoute(from text: String) throws -> [RouteCoordinate] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw GPXError.empty }

        let coordinates = trimmed.contains("<coordinates>")
            ? parseKML(trimmed)
            : parseGPX(trimmed)

        guard !coordinates.isEmpty else { throw GPXError.invalidFormat }
        return coordinates
    }

    // MARK: - Parsing

    private func parseGPX(_ text: String) -> [RouteCoordinate] {
        matches(in: text, pattern: #"<(?:trkpt|wpt|rtept)\b([^>]*)>"#).compactMap { attributes in
            guard let latitude = attribute("lat", in: attributes),
                  let longitude = attribute("lon", in: attributes)
            else { return nil }
            return RouteCoordinate(latitude: latitude, longitude: longitude)
        }
    }

    private func parseKML(_ text: String) -> [RouteCoordinate] {
        matches(in: text, pattern: #"<coordinates>([\s\S]*?)</coordinates>"#)
            .flatMap { block in
                block.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" || $0 == "\r" })
                    .compactMap { token -> RouteCoordinate? in
                        let parts = token.split(separator: ",")
                        guard parts.count >= 2,
                              let longitude = Double(parts[0]),
                              let latitude = Double(parts[1])
                        else { return nil }
                        return RouteCoordinate(latitude: latitude, longitude: longitude)
                    }
            }
    }

    private func attribute(_ name: String, in attributes: String) -> Double? {
        guard let value = matches(in: attributes, pattern: "\(name)\\s*=\\s*\"([^\"]+)\"").first else {
            return nil
        }
        return Double(value)
    }

    /// Returns the first capture group's value for each match.
    private func matches(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let groupRange = Range(match.range(at: 1), in: text)
            else { return nil }
            return String(text[groupRange])
        }
    }
}
