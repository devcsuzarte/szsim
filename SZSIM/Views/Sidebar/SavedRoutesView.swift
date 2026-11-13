//
//  SavedRoutesView.swift
//  SZSIM
//

import SwiftUI

/// "Saved" tab: search, load, and delete saved routes.
struct SavedRoutesView: View {
    let viewModel: MainViewModel
    @Bindable var model: SavedRoutesViewModel

    @State private var routeToDelete: SavedRoute?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Search saved routes", text: $model.searchText)
                .textFieldStyle(.roundedBorder)

            if model.filteredRoutes.isEmpty {
                Text(model.routes.isEmpty ? "No saved routes" : "No results")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(model.filteredRoutes) { route in
                            savedRow(route)
                        }
                    }
                }
                .scrollIndicators(.never)
            }
        }
        .alert("Delete route?", isPresented: deleteAlertBinding, presenting: routeToDelete) { route in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { delete(route) }
        } message: { route in
            Text("\"\(route.name)\" will be permanently removed.")
        }
    }

    private func savedRow(_ route: SavedRoute) -> some View {
        HStack(spacing: 8) {
            Button {
                viewModel.load(route)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(route.name)
                        .fontWeight(.medium)
                    Text(summary(for: route))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                routeToDelete = route
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Delete route")
        }
        .padding(10)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(get: { routeToDelete != nil }, set: { if !$0 { routeToDelete = nil } })
    }

    private func delete(_ route: SavedRoute) {
        try? model.delete(route)
        routeToDelete = nil
    }

    private func summary(for route: SavedRoute) -> String {
        let kilometers = String(format: "%.1f", route.distanceMeters / 1000)
        let date = route.updatedAt.formatted(date: .numeric, time: .omitted)
        return "\(kilometers) km · \(date)"
    }
}
