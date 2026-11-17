//
//  MainWindow.swift
//  SZSIM
//

import SwiftData
import SwiftUI

/// Main window: sidebar + map + playback bar, or the empty state when there is
/// no Booted simulator.
struct MainWindow: View {
    @State private var viewModel = MainViewModel()
    @State private var savedPoints: SavedPointsViewModel?
    @Environment(\.modelContext) private var modelContext
    @AppStorage(PreferenceKey.sendFrequencyHz)
    private var sendFrequencyHz = PreferenceKey.defaultSendFrequencyHz
    @AppStorage(PreferenceKey.defaultProfile)
    private var defaultProfile = MovementProfile.driving.rawValue

    var body: some View {
        Group {
            if viewModel.hasBootedDevice {
                NavigationSplitView {
                    SidebarView(viewModel: viewModel, savedPoints: savedPoints)
                        .navigationSplitViewColumnWidth(min: 300, ideal: 320, max: 400)
                } detail: {
                    detail
                }
            } else {
                NoSimulatorView(
                    onOpenSimulator: viewModel.openSimulator,
                    onRefresh: { Task { await viewModel.refreshDevices() } }
                )
            }
        }
        .task {
            if savedPoints == nil {
                savedPoints = SavedPointsViewModel(context: modelContext)
            }
            // Detects simulators and re-polls every 3 s (appear/disappear).
            await viewModel.refreshDevices()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                await viewModel.refreshDevices()
            }
        }
        .onAppear(perform: applyPreferences)
        .onChange(of: sendFrequencyHz) { applyPreferences() }
        .onChange(of: defaultProfile) { applyPreferences() }
        .onChange(of: viewModel.panelMode) { viewModel.pause() }
    }

    /// Applies the send frequency (tickInterval) and the default profile (if there is no route yet).
    private func applyPreferences() {
        let clampedHz = max(1, min(sendFrequencyHz, PreferenceKey.maxSendFrequencyHz))
        viewModel.playback.tickInterval = 1.0 / Double(clampedHz)
        if viewModel.waypoints.isEmpty, let profile = MovementProfile(rawValue: defaultProfile) {
            viewModel.playback.profile = profile
        }
    }

    private var detail: some View {
        VStack(spacing: 0) {
            RouteMapView(viewModel: viewModel, savedPoints: savedPoints)
                .overlay(alignment: .bottom) {
                    if let toast = viewModel.toast {
                        ToastView(message: toast)
                            .padding(.bottom, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.toast)
            Divider()
            bottomBar
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if viewModel.panelMode == .point {
            if let savedPoints {
                PointBarView(viewModel: viewModel, savedPoints: savedPoints)
            }
        } else {
            PlaybackBarView(viewModel: viewModel, engine: viewModel.playback)
        }
    }
}
