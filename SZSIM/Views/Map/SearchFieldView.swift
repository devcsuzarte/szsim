//
//  SearchFieldView.swift
//  SZSIM
//

import CoreLocation
import SwiftUI

/// Search field over the map: autocomplete (MapKit) or a pasted "lat, lon".
struct SearchFieldView: View {
    @Bindable var viewModel: MainViewModel
    @State private var text = ""
    @FocusState private var focused: Bool

    /// Called when the user picks a location (suggestion, Enter, or coordinate).
    var onPick: (CLLocationCoordinate2D) -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search address or paste lat, lon", text: $text)
                    .textFieldStyle(.plain)
                    .focused($focused)
                    .onSubmit(submit)
                    .onChange(of: text) {
                        viewModel.search.update(query: text)
                    }
            }
            .padding(10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.12), radius: 6, y: 2)

            if focused, !viewModel.search.suggestions.isEmpty {
                suggestions
            }
        }
    }

    private var suggestions: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.search.suggestions.prefix(6)) { suggestion in
                Button {
                    pick(suggestion)
                } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(suggestion.title)
                            .foregroundStyle(.primary)
                        if !suggestion.subtitle.isEmpty {
                            Text(suggestion.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Divider()
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
    }

    private func submit() {
        let query = text
        Task {
            if let coordinate = try? await viewModel.search.search(query) {
                deliver(coordinate)
            }
        }
    }

    private func pick(_ suggestion: SearchSuggestion) {
        Task {
            if let coordinate = try? await viewModel.search.resolve(suggestion) {
                deliver(coordinate)
            }
        }
    }

    private func deliver(_ coordinate: CLLocationCoordinate2D) {
        onPick(coordinate)
        text = ""
        focused = false
        viewModel.search.update(query: "")
    }
}
