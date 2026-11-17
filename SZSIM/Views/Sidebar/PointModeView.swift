//
//  PointModeView.swift
//  SZSIM
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// "Point" mode panel: the selected point card and the saved points list.
struct PointModeView: View {
    @Bindable var viewModel: MainViewModel
    @Bindable var savedPoints: SavedPointsViewModel

    @State private var showingSaveSheet = false
    @State private var pointToDelete: SavedPoint?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            selectedPointSection
            savedPointsSection
            Spacer(minLength: 0)
        }
        .sheet(isPresented: $showingSaveSheet) {
            SavePointSheet(viewModel: viewModel, savedPoints: savedPoints)
        }
        .alert("Delete point?", isPresented: deleteAlertBinding, presenting: pointToDelete) { point in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { delete(point) }
        } message: { point in
            Text("\"\(point.name)\" will be permanently removed.")
        }
    }

    // MARK: - Selected point

    private var selectedPointSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("SELECTED POINT")

            if let point = viewModel.selectedPoint {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(point.displayName)
                            .font(.callout)
                            .fontWeight(.medium)
                        Text(point.addressText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.5f, %.5f", point.coordinate.latitude, point.coordinate.longitude))
                            .font(.caption2)
                            .monospaced()
                            .foregroundStyle(.secondary)
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 8) {
                    Button(action: { showingSaveSheet = true }) {
                        Label("Save point", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }

                    Button(action: setOnSimulator) {
                        Label("Set on simulator", systemImage: "location.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.selectedDevice == nil)
                }

                Button(action: { exportGPX(point) }) {
                    Label("Export GPX", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
            } else {
                Text("Click the map or search for an address to select a point.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func setOnSimulator() {
        Task { await viewModel.setSelectedPointOnSimulator() }
    }

    private func exportGPX(_ point: PointSelection) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(point.displayName).gpx"
        panel.allowedContentTypes = [UTType(filenameExtension: "gpx") ?? .xml]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let gpx = GPXService().export(pointName: point.displayName, coordinate: point.coordinate)
        try? gpx.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Saved points

    private var savedPointsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("SAVED POINTS")

            TextField("Search saved points", text: $savedPoints.searchText)
                .textFieldStyle(.roundedBorder)

            if savedPoints.filteredPoints.isEmpty {
                Text(savedPoints.points.isEmpty
                    ? "No saved points yet. Click the map or search for an address, then use Save point."
                    : "No results")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(savedPoints.filteredPoints) { point in
                            savedRow(point)
                        }
                    }
                }
                .scrollIndicators(.never)
            }
        }
    }

    private func savedRow(_ point: SavedPoint) -> some View {
        HStack(spacing: 8) {
            Button {
                viewModel.selectSavedPoint(point)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(point.name)
                        .fontWeight(.medium)
                    Text(point.address ?? String(format: "%.5f, %.5f", point.latitude, point.longitude))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                send(point)
            } label: {
                Image(systemName: "location.fill")
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.selectedDevice == nil)
            .help("Set on simulator")

            Button(role: .destructive) {
                pointToDelete = point
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Delete point")
        }
        .padding(10)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(get: { pointToDelete != nil }, set: { if !$0 { pointToDelete = nil } })
    }

    private func send(_ point: SavedPoint) {
        Task {
            if await viewModel.sendSavedPoint(point) {
                try? savedPoints.touch(point)
            }
        }
    }

    private func delete(_ point: SavedPoint) {
        try? savedPoints.delete(point)
        pointToDelete = nil
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
    }
}
