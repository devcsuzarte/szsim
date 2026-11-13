//
//  RouteMapView.swift
//  SZSIM
//

import MapKit
import SwiftUI

/// Map with the route, point markers, and the position indicator.
///
/// Clicking the map adds a waypoint (via `MapReader` → `convert`).
struct RouteMapView: View {
    @Bindable var viewModel: MainViewModel
    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -23.561, longitude: -46.656),
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
    )

    var body: some View {
        MapReader { proxy in
            Map(position: $camera) {
                mapContent
            }
            .onTapGesture { location in
                guard let coordinate = proxy.convert(location, from: .local) else { return }
                add(coordinate)
            }
        }
        .overlay(alignment: .top) {
            SearchFieldView(viewModel: viewModel) { coordinate in
                add(coordinate)
                camera = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))
            }
            .frame(maxWidth: 420)
            .padding(12)
        }
        .overlay(alignment: .topTrailing) {
            if viewModel.playback.totalDistance > 0 {
                TelemetryCardView(viewModel: viewModel)
                    .padding(12)
            }
        }
        .onChange(of: viewModel.mapFitToken) {
            fitCameraToRoute()
        }
    }

    /// Frames the camera on the current polyline (when loading or importing a route).
    private func fitCameraToRoute() {
        let coordinates = viewModel.polyline
        guard !coordinates.isEmpty else { return }
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        guard let minLat = latitudes.min(), let maxLat = latitudes.max(),
              let minLon = longitudes.min(), let maxLon = longitudes.max()
        else { return }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.005),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.005)
        )
        withAnimation(.easeInOut) {
            camera = .region(MKCoordinateRegion(center: center, span: span))
        }
    }

    @MapContentBuilder
    private var mapContent: some MapContent {
        ForEach(Array(viewModel.waypoints.enumerated()), id: \.element.id) { index, waypoint in
            Annotation("", coordinate: waypoint.coordinate) {
                marker(index: index, waypoint: waypoint)
            }
        }

        if viewModel.polyline.count > 1 {
            MapPolyline(coordinates: viewModel.polyline.map(\.coordinate))
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
        }

        if viewModel.playback.totalDistance > 0, let position = viewModel.currentCoordinate {
            Annotation("", coordinate: position.coordinate) {
                positionMarker
            }
        }
    }

    private func marker(index: Int, waypoint: Waypoint) -> some View {
        ZStack {
            Circle()
                .fill(markerColor(waypoint.kind))
                .frame(width: 26, height: 26)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
            Text(markerLabel(index: index, waypoint: waypoint))
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
    }

    private var positionMarker: some View {
        Image(systemName: "location.north.fill")
            .font(.caption)
            .foregroundStyle(.white)
            .padding(6)
            .background(Circle().fill(Color.blue))
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .rotationEffect(.degrees(viewModel.currentHeading))
    }

    private func add(_ coordinate: CLLocationCoordinate2D) {
        viewModel.addWaypoint(coordinate)
        Task { await viewModel.rebuildRoute() }
    }

    private func markerColor(_ kind: Waypoint.Kind) -> Color {
        switch kind {
        case .origin: .green
        case .stop: .orange
        case .destination: .red
        }
    }

    private func markerLabel(index: Int, waypoint: Waypoint) -> String {
        switch waypoint.kind {
        case .origin: "A"
        case .destination: "B"
        case .stop: "\(viewModel.waypoints[...index].filter { $0.kind == .stop }.count)"
        }
    }
}
