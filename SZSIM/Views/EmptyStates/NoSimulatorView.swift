//
//  NoSimulatorView.swift
//  SZSIM
//

import SwiftUI

/// State shown when no simulator has Booted status.
struct NoSimulatorView: View {
    var onOpenSimulator: () -> Void
    var onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(.quaternary)
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "iphone")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                }

            Text("No simulator running")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Open an iOS simulator to start sending locations. SZSIM automatically detects devices with Booted status.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

            Text(verbatim: "xcrun simctl boot \"iPhone 16 Pro\"")
                .font(.system(.footnote, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 12) {
                Button(action: onOpenSimulator) {
                    Text("Open Simulator")
                }
                .buttonStyle(.borderedProminent)

                Button(action: onRefresh) {
                    Text("Refresh")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 4)

            Text("Requires Xcode 14 or later")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NoSimulatorView(onOpenSimulator: {}, onRefresh: {})
        .frame(width: 640, height: 480)
}
