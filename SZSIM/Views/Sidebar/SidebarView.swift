//
//  SidebarView.swift
//  SZSIM
//

import SwiftUI

/// Sidebar tabs: "Current route" and "Saved".
struct SidebarView: View {
    @Bindable var viewModel: MainViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var savedRoutes: SavedRoutesViewModel?
    @State private var tab: Tab = .current

    enum Tab: Hashable {
        case current
        case saved
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            brandHeader

            Picker("Tab", selection: $tab) {
                Text("Current route").tag(Tab.current)
                Text("Saved (\(savedRoutes?.routes.count ?? 0))").tag(Tab.saved)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            content

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            if savedRoutes == nil {
                savedRoutes = SavedRoutesViewModel(context: modelContext)
            }
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 10) {
            LogoMark(size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text("SZSIM")
                    .font(.headline)
                Text("Route simulator for iOS")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .current:
            CurrentRouteView(viewModel: viewModel, savedRoutes: savedRoutes)
        case .saved:
            if let savedRoutes {
                SavedRoutesView(viewModel: viewModel, model: savedRoutes)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
