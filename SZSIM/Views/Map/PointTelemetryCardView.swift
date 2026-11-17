//
//  PointTelemetryCardView.swift
//  SZSIM
//

import SwiftUI

/// Floating card with the selected point's coordinate and send status
/// (the Point-mode counterpart of `TelemetryCardView`).
struct PointTelemetryCardView: View {
    let point: PointSelection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                GridRow {
                    field("Latitude", value: formatted(point.coordinate.latitude))
                    field("Longitude", value: formatted(point.coordinate.longitude))
                }
            }
            HStack(spacing: 6) {
                Circle()
                    .fill(point.isSent ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(point.sendStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

    private func formatted(_ value: Double) -> String {
        String(format: "%.5f", value)
    }
}
