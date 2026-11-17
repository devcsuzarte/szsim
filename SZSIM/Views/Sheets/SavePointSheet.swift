//
//  SavePointSheet.swift
//  SZSIM
//

import SwiftUI

/// Sheet to name and save the selected point, with overwrite confirmation.
struct SavePointSheet: View {
    let viewModel: MainViewModel
    let savedPoints: SavedPointsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var showOverwrite = false
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Save point")
                .font(.headline)

            TextField("Point name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { save(overwrite: false) }

            if let point = viewModel.selectedPoint {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.5f, %.5f", point.coordinate.latitude, point.coordinate.longitude))
                        .font(.caption)
                        .monospaced()
                        .foregroundStyle(.secondary)
                    Text(point.address ?? "Address unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

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
                    .disabled(trimmedName.isEmpty || viewModel.selectedPoint == nil)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear { name = viewModel.selectedPoint?.name ?? "" }
        .alert("A point named \"\(trimmedName)\" already exists. Overwrite?", isPresented: $showOverwrite) {
            Button("Cancel", role: .cancel) {}
            Button("Overwrite", role: .destructive) { save(overwrite: true) }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save(overwrite: Bool) {
        guard !trimmedName.isEmpty, let point = viewModel.selectedPoint else { return }
        do {
            try savedPoints.save(
                name: trimmedName,
                coordinate: point.coordinate,
                address: point.address,
                overwrite: overwrite
            )
            viewModel.selectedPoint?.name = trimmedName
            viewModel.showToast("Point saved")
            dismiss()
        } catch StorageError.nameExists {
            showOverwrite = true
        } catch {
            errorText = "Failed to save: \(error.localizedDescription)"
        }
    }
}
