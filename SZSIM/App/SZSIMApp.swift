//
//  SZSIMApp.swift
//  SZSIM
//

import SwiftData
import SwiftUI

@main
struct SZSIMApp: App {
    let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: SavedRoute.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainWindow()
        }
        .defaultSize(width: 1440, height: 900)
        .modelContainer(modelContainer)

        Settings {
            SettingsView()
        }
    }
}
