//
//  PreferenceKey.swift
//  SZSIM
//

import Foundation

/// Keys and defaults for the preferences persisted in `UserDefaults`.
enum PreferenceKey {
    static let sendFrequencyHz = "sendFrequencyHz"
    static let defaultProfile = "defaultProfile"

    static let defaultSendFrequencyHz = 1
    static let maxSendFrequencyHz = 10
}
