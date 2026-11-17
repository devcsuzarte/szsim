//
//  PlaybackBarView.swift
//  SZSIM
//

import SwiftUI

/// Bottom playback bar: transport, progress, speed, profile, and loop.
struct PlaybackBarView: View {
    let viewModel: MainViewModel
    @Bindable var engine: PlaybackEngine

    var body: some View {
        VStack(spacing: 10) {
            transportRow
            optionsRow
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
        .onChange(of: engine.profile) {
            Task { await viewModel.rebuildRoute() }
        }
    }

    // MARK: - Transport + progress

    private var transportRow: some View {
        HStack(spacing: 12) {
            Button(action: viewModel.reset) {
                Image(systemName: "backward.end.fill")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("r", modifiers: .command)
            .help("Back to start (⌘R)")

            Button(action: togglePlay) {
                Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(playEnabled ? Color.accentColor : Color.secondary))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!playEnabled)
            .keyboardShortcut(.space, modifiers: [])
            .help("Play/Pause (Space)")

            Text(clock(engine.playbackElapsed))
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Slider(value: progressBinding, in: 0...1)

            Text(clock(engine.playbackDuration))
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Speed, profile, loop, status

    private var optionsRow: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Text("Speed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(PlaybackSpeed.allCases) { speed in
                    chip(label: speedLabel(speed), isSelected: engine.speed == speed) {
                        engine.speed = speed
                    }
                }
            }

            HStack(spacing: 6) {
                Text("Profile")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(MovementProfile.allCases) { profile in
                    chip(label: profileLabel(profile), isSelected: engine.profile == profile) {
                        engine.profile = profile
                    }
                }
            }

            Toggle("Loop", isOn: $engine.loops)
                .toggleStyle(.checkbox)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(engine.isPlaying ? Color.green : Color.secondary)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func chip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private var playEnabled: Bool {
        engine.isPlaying || viewModel.canPlay
    }

    private func togglePlay() {
        if engine.isPlaying {
            viewModel.pause()
        } else {
            viewModel.play()
        }
    }

    private var progressBinding: Binding<Double> {
        Binding(get: { engine.progress }, set: { engine.seek(toProgress: $0) })
    }

    private var statusText: String {
        let state = engine.isPlaying ? "Playing" : "Paused"
        let device = viewModel.selectedDevice?.name ?? "—"
        return "\(state) · \(device)"
    }

    private func clock(_ time: TimeInterval) -> String {
        let seconds = Int(time.rounded())
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func speedLabel(_ speed: PlaybackSpeed) -> String {
        speed.multiplier == 0.5 ? "0.5×" : "\(Int(speed.multiplier))×"
    }

    private func profileLabel(_ profile: MovementProfile) -> String {
        switch profile {
        case .walking: "Walk"
        case .cycling: "Bike"
        case .driving: "Car"
        }
    }
}
