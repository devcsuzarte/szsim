//
//  CurrentRouteView.swift
//  SZSIM
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// "Current route" tab: simulator, route mode, points, and summary.
struct CurrentRouteView: View {
    @Bindable var viewModel: MainViewModel
    var savedRoutes: SavedRoutesViewModel?
    @State private var showingSaveSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                simulatorSection
                modeSection
                pointsSection
                summarySection
                saveButton
                gpxButtons
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.never)
        .sheet(isPresented: $showingSaveSheet) {
            if let savedRoutes {
                SaveRouteSheet(viewModel: viewModel, savedRoutes: savedRoutes)
            }
        }
    }

    private var saveButton: some View {
        Button {
            showingSaveSheet = true
        } label: {
            Label("Save route", systemImage: "square.and.arrow.down")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.polyline.isEmpty || savedRoutes == nil)
    }

    // MARK: - Simulator

    private var simulatorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("SIMULATOR")
            Picker("Simulator", selection: $viewModel.selectedDeviceID) {
                ForEach(viewModel.devices) { device in
                    Text("\(device.name) — \(device.runtime)").tag(Optional(device.id))
                }
            }
            .labelsHidden()

            if let device = viewModel.selectedDevice {
                HStack(spacing: 6) {
                    Circle()
                        .fill(device.isBooted ? Color.green : Color.secondary)
                        .frame(width: 8, height: 8)
                    Text("\(device.isBooted ? "Booted" : device.state.rawValue) · UDID \(shortUDID(device.udid))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        Task { await viewModel.refreshDevices() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .help("Refresh simulator list")
                }
            }
        }
    }

    // MARK: - Route mode

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("ROUTE MODE")
            Picker("Mode", selection: $viewModel.mode) {
                Text("Follow streets").tag(RouteMode.streets)
                Text("Straight line").tag(RouteMode.straight)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: viewModel.mode) {
                Task { await viewModel.rebuildRoute() }
            }
        }
    }

    // MARK: - Points

    private var pointsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionTitle("POINTS")
                Spacer()
                Text("Click the map to add")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if viewModel.waypoints.isEmpty {
                Text("No points yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(Array(viewModel.waypoints.enumerated()), id: \.element.id) { index, waypoint in
                    waypointRow(index: index, waypoint: waypoint)
                }
            }
        }
    }

    private func waypointRow(index: Int, waypoint: Waypoint) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(markerColor(waypoint.kind)).frame(width: 28, height: 28)
                Text(markerLabel(index: index, waypoint: waypoint))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(kindLabel(waypoint.kind))
                    .font(.callout)
                    .fontWeight(.medium)
                Text(String(format: "%.5f, %.5f", waypoint.latitude, waypoint.longitude))
                    .font(.caption2)
                    .monospaced()
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                viewModel.removeWaypoint(id: waypoint.id)
                Task { await viewModel.rebuildRoute() }
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Summary

    private var summarySection: some View {
        HStack(spacing: 12) {
            summaryCard(title: "Distance", value: formattedDistance)
            summaryCard(title: "Duration (1×)", value: formattedDuration)
        }
    }

    private func summaryCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - GPX

    private var gpxButtons: some View {
        HStack(spacing: 8) {
            Button(action: importGPX) {
                Label("Import GPX", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }

            Button(action: exportGPX) {
                Label("Export GPX", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .disabled(viewModel.polyline.isEmpty)
        }
    }

    private func importGPX() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = ["gpx", "kml", "xml"].compactMap { UTType(filenameExtension: $0) }
        guard panel.runModal() == .OK,
              let url = panel.url,
              let text = try? String(contentsOf: url, encoding: .utf8),
              let coordinates = try? GPXService().importRoute(from: text)
        else { return }
        viewModel.importPolyline(coordinates)
    }

    private func exportGPX() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "route.gpx"
        panel.allowedContentTypes = [UTType(filenameExtension: "gpx") ?? .xml]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let gpx = GPXService().export(
            polyline: viewModel.polyline,
            profile: viewModel.playback.profile,
            name: "SZSIM"
        )
        try? gpx.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
    }

    private func shortUDID(_ udid: String) -> String {
        guard udid.count > 8 else { return udid }
        return "\(udid.prefix(4))...\(udid.suffix(4))"
    }

    private func markerColor(_ kind: Waypoint.Kind) -> Color {
        switch kind {
        case .origin: .green
        case .stop: .orange
        case .destination: .red
        }
    }

    private func kindLabel(_ kind: Waypoint.Kind) -> String {
        switch kind {
        case .origin: "Origin"
        case .stop: "Stop"
        case .destination: "Destination"
        }
    }

    private func markerLabel(index: Int, waypoint: Waypoint) -> String {
        switch waypoint.kind {
        case .origin: "A"
        case .destination: "B"
        case .stop: "\(viewModel.waypoints[...index].filter { $0.kind == .stop }.count)"
        }
    }

    private var formattedDistance: String {
        let kilometers = viewModel.distanceMeters / 1000
        return String(format: "%.1f km", kilometers)
    }

    private var formattedDuration: String {
        let total = Int(viewModel.playback.routeDuration1x.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
