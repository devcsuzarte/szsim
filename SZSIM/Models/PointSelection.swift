//
//  PointSelection.swift
//  SZSIM
//

import Foundation

/// Which side of the feature the user is working on: a single point or a route.
enum PanelMode: String, CaseIterable, Identifiable {
    case point
    case route

    var id: String { rawValue }
}

/// The point currently selected on the map (not necessarily saved).
///
/// Ephemeral UI state owned by `MainViewModel`, mirroring how `waypoints` live
/// there. The address is resolved once per selection via reverse geocoding;
/// `nil` means it could not be resolved ("Address unavailable").
struct PointSelection: Equatable {
    var name: String?
    var coordinate: RouteCoordinate
    var address: String?
    var isResolvingAddress: Bool
    var lastSend: PointSend?

    init(
        name: String? = nil,
        coordinate: RouteCoordinate,
        address: String? = nil,
        isResolvingAddress: Bool = false,
        lastSend: PointSend? = nil
    ) {
        self.name = name
        self.coordinate = coordinate
        self.address = address
        self.isResolvingAddress = isResolvingAddress
        self.lastSend = lastSend
    }

    var displayName: String {
        guard let name, !name.isEmpty else { return "Unnamed point" }
        return name
    }

    var addressText: String {
        if let address { return address }
        return isResolvingAddress ? "Resolving…" : "Address unavailable"
    }

    var isSent: Bool { lastSend != nil }

    /// Human-readable send status for the card, bar, and telemetry.
    var sendStatusText: String {
        guard let lastSend else { return "Not sent to the simulator yet" }
        let time = lastSend.date.formatted(date: .omitted, time: .shortened)
        return "Set on \(lastSend.deviceName) at \(time)"
    }
}

/// Records the last successful send of a point to a simulator.
struct PointSend: Equatable {
    var deviceName: String
    var date: Date
}
