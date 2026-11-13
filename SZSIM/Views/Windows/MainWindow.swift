//
//  MainWindow.swift
//  SZSIM
//

import SwiftUI

/// Main window: sidebar + map + playback bar, or the empty state when there is
/// no Booted simulator.
struct MainWindow: View {
    @State private var viewModel = MainViewModel()
    @AppStorage(PreferenceKey.sendFrequencyHz)
    private var sendFrequencyHz = PreferenceKey.defaultSendFrequencyHz
    @AppStorage(PreferenceKey.defaultProfile)
    private var defaultProfile = MovementProfile.driving.rawValue

    var body: some View {
        Group {
            if viewModel.hasBootedDevice {
                NavigationSplitView {
                    SidebarView(viewModel: viewModel)
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
            RouteMapView(viewModel: viewModel)
            Divider()
            PlaybackBarView(viewModel: viewModel, engine: viewModel.playback)
        }
    }
}
