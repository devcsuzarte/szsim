//
//  SavedRoutesViewModelTests.swift
//  SZSIMTests
//

import SwiftData
import Testing
@testable import SZSIM

@MainActor
struct SavedRoutesViewModelTests {
    private func makeViewModel() throws -> SavedRoutesViewModel {
        let container = try ModelContainer(
            for: SavedRoute.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SavedRoutesViewModel(context: ModelContext(container))
    }

    private func save(
        _ viewModel: SavedRoutesViewModel,
        name: String,
        distance: Double = 100,
        overwrite: Bool = false
    ) throws {
        try viewModel.save(
            name: name,
            waypoints: [],
            mode: .streets,
            profile: .driving,
            speed: .normal,
            polyline: [],
            distanceMeters: distance,
            overwrite: overwrite
        )
    }

    @Test func saveInsertsRoute() throws {
        let viewModel = try makeViewModel()
        try save(viewModel, name: "Paulista")
        #expect(viewModel.routes.count == 1)
        #expect(viewModel.routes.first?.name == "Paulista")
    }

    @Test func filtersBySearchText() throws {
        let viewModel = try makeViewModel()
        try save(viewModel, name: "Paulista")
        try save(viewModel, name: "República")
        viewModel.searchText = "paul"
        #expect(viewModel.filteredRoutes.count == 1)
        #expect(viewModel.filteredRoutes.first?.name == "Paulista")
    }

    @Test func savingDuplicateNameWithoutOverwriteThrows() throws {
        let viewModel = try makeViewModel()
        try save(viewModel, name: "Paulista")
        #expect(throws: StorageError.self) {
            try save(viewModel, name: "Paulista")
        }
    }

    @Test func overwriteUpdatesExistingRoute() throws {
        let viewModel = try makeViewModel()
        try save(viewModel, name: "Paulista", distance: 100)
        try save(viewModel, name: "Paulista", distance: 200, overwrite: true)
        #expect(viewModel.routes.count == 1)
        #expect(viewModel.routes.first?.distanceMeters == 200)
    }

    @Test func deleteRemovesRoute() throws {
        let viewModel = try makeViewModel()
        try save(viewModel, name: "Paulista")
        let route = try #require(viewModel.routes.first)
        try viewModel.delete(route)
        #expect(viewModel.routes.isEmpty)
    }
}
