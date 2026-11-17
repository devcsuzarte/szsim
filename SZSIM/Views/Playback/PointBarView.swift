//
//  PointBarView.swift
//  SZSIM
//

import SwiftUI

/// Bottom bar for Point mode: the current point plus "Save point" and
/// "Set on simulator" (replaces the playback controls).
struct PointBarView: View {
    @Bindable var viewModel: MainViewModel
    let savedPoints: SavedPointsViewModel

    @State private var showingSaveSheet = false

    var body: some View {
        HStack(spacing: 16) {
            info
            Spacer()

            Button(action: { showingSaveSheet = true }) {
                Label("Save point", systemImage: "square.and.arrow.down")
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(viewModel.selectedPoint == nil)

            Button(action: setOnSimulator) {
                Label("Set on simulator", systemImage: "location.fill")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(viewModel.selectedPoint == nil || viewModel.selectedDevice == nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
        .sheet(isPresented: $showingSaveSheet) {
            SavePointSheet(viewModel: viewModel, savedPoints: savedPoints)
        }
    }

    @ViewBuilder
    private var info: some View {
        if let point = viewModel.selectedPoint {
            VStack(alignment: .leading, spacing: 2) {
                Text(point.displayName)
                    .font(.callout)
                    .fontWeight(.medium)
                HStack(spacing: 8) {
                    Text(String(format: "%.5f, %.5f", point.coordinate.latitude, point.coordinate.longitude))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(point.isSent ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(point.sendStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } else {
            Text("Click the map or search for an address to select a point.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func setOnSimulator() {
        Task { await viewModel.setSelectedPointOnSimulator() }
    }
}
