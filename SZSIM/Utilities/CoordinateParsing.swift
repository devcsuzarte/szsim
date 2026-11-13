//
//  CoordinateParsing.swift
//  SZSIM
//

import CoreLocation

/// Interprets text pasted into the search field as "lat, lon".
enum CoordinateParser {
    /// Returns the coordinate when the text is a valid "lat, lon" pair; otherwise `nil`.
    static func parse(_ text: String) -> CLLocationCoordinate2D? {
        let parts = text.split(separator: ",")
        guard parts.count == 2,
              let latitude = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let longitude = Double(parts[1].trimmingCharacters(in: .whitespaces)),
              (-90...90).contains(latitude),
              (-180...180).contains(longitude)
        else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
