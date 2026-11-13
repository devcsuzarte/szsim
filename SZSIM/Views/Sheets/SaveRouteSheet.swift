//
//  SaveRouteSheet.swift
//  SZSIM
//

import SwiftUI

/// Sheet to name and save the current route, with overwrite confirmation.
struct SaveRouteSheet: View {
    let viewModel: MainViewModel
    let savedRoutes: SavedRoutesViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var showOverwrite = false
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Save route")
                .font(.headline)

            TextField("Route name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { save(overwrite: false) }

            if let errorText {
                Text(errorText)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { save(overwrite: false) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(trimmedName.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 360)
        .alert("A route named \"\(trimmedName)\" already exists. Overwrite?", isPresented: $showOverwrite) {
            Button("Cancel", role: .cancel) {}
            Button("Overwrite", role: .destructive) { save(overwrite: true) }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save(overwrite: Bool) {
        guard !trimmedName.isEmpty else { return }
        do {
            try savedRoutes.save(
                name: trimmedName,
                waypoints: viewModel.waypoints,
                mode: viewModel.mode,
                profile: viewModel.playback.profile,
                speed: viewModel.playback.speed,
                polyline: viewModel.polyline,
                distanceMeters: viewModel.distanceMeters,
                overwrite: overwrite
            )
            dismiss()
        } catch StorageError.nameExists {
            showOverwrite = true
        } catch {
            errorText = "Failed to save: \(error.localizedDescription)"
        }
    }
}
