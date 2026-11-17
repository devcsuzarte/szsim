//
//  GeocodingService.swift
//  SZSIM
//

import Contacts
import CoreLocation
import os

/// Resolves a coordinate into a human-readable address. Abstracted behind a
/// protocol so it can be stubbed in tests.
protocol ReverseGeocoding: Sendable {
    /// Returns a one-line address, or `nil` when it cannot be resolved.
    func address(for coordinate: CLLocationCoordinate2D) async -> String?
}

/// `CLGeocoder`-backed reverse geocoding. Called once per selection, never in a
/// loop. A fresh `CLGeocoder` is used per call to avoid shared-state contention.
struct GeocodingService: ReverseGeocoding {
    private static let logger = Logger(subsystem: "com.szsim.app", category: "geocoding")

    func address(for coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            return Self.oneLineAddress(from: placemark)
        } catch {
            Self.logger.error("Reverse geocoding failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func oneLineAddress(from placemark: CLPlacemark) -> String? {
        if let postalAddress = placemark.postalAddress {
            let formatted = CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
                .split(separator: "\n")
                .joined(separator: ", ")
            if !formatted.isEmpty { return formatted }
        }
        return placemark.name
    }
}
