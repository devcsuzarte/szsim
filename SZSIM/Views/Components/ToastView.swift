//
//  ToastView.swift
//  SZSIM
//

import SwiftUI

/// Brief confirmation banner shown over the map after an action.
struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.callout)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.18), radius: 8, y: 2)
    }
}
