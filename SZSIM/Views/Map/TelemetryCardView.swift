//
//  TelemetryCardView.swift
//  SZSIM
//

import SwiftUI

/// Floating card with the current position's telemetry.
struct TelemetryCardView: View {
    @Bindable var viewModel: MainViewModel

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
            GridRow {
                field("Latitude", value: formatted(viewModel.currentCoordinate?.latitude))
                field("Longitude", value: formatted(viewModel.currentCoordinate?.longitude))
            }
            GridRow {
                field("Speed", value: speedText)
                field("Direction", value: headingText)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
    }

    private func field(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }

    private func formatted(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.5f", value)
    }

    private var speedText: String {
        String(format: "%.1f m/s", viewModel.currentSpeedMetersPerSecond)
    }

    private var headingText: String {
        let heading = viewModel.currentHeading
        return "\(Int(heading.rounded()))° \(compass(heading))"
    }

    private func compass(_ degrees: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((degrees / 45).rounded()) % directions.count
        return directions[index]
    }
}
