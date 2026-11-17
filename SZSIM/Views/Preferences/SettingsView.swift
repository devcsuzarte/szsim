//
//  SettingsView.swift
//  SZSIM
//

import SwiftUI

/// App preferences (Settings scene, ⌘,).
struct SettingsView: View {
    @AppStorage(PreferenceKey.sendFrequencyHz)
    private var sendFrequencyHz = PreferenceKey.defaultSendFrequencyHz
    @AppStorage(PreferenceKey.defaultProfile)
    private var defaultProfile = MovementProfile.driving.rawValue

    var body: some View {
        Form {
            Section("Location sending") {
                Stepper(value: $sendFrequencyHz, in: 1...PreferenceKey.maxSendFrequencyHz) {
                    Text("Frequency: \(sendFrequencyHz) Hz")
                }
                Text("How often the position is sent to the simulator (max \(PreferenceKey.maxSendFrequencyHz) Hz).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Route") {
                Picker("Default profile", selection: $defaultProfile) {
                    Text("Walk").tag(MovementProfile.walking.rawValue)
                    Text("Bike").tag(MovementProfile.cycling.rawValue)
                    Text("Car").tag(MovementProfile.driving.rawValue)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 260)
    }
}
