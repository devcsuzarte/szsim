//
//  SavedPointsViewModelTests.swift
//  SZSIMTests
//

import SwiftData
import Testing
@testable import SZSIM

@MainActor
struct SavedPointsViewModelTests {
    private func makeViewModel() throws -> SavedPointsViewModel {
        let container = try ModelContainer(
            for: SavedPoint.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SavedPointsViewModel(context: ModelContext(container))
    }

    private func save(
        _ viewModel: SavedPointsViewModel,
        name: String,
        latitude: Double = -23.5,
        longitude: Double = -46.6,
        address: String? = nil,
        overwrite: Bool = false
    ) throws {
        try viewModel.save(
            name: name,
            coordinate: RouteCoordinate(latitude: latitude, longitude: longitude),
            address: address,
            overwrite: overwrite
        )
    }

    @Test func saveInsertsPoint() throws {
        let viewModel = try makeViewModel()
        try save(viewModel, name: "Home")
        #expect(viewModel.points.count == 1)
        #expect(viewModel.points.first?.name == "Home")
    }

    @Test func filtersByNameOrAddress() throws {
        let viewModel = try makeViewModel()
        try save(viewModel, name: "Home", address: "Av. Paulista, 1000")
        try save(viewModel, name: "Office", address: "Rua da Consolação, 50")

        viewModel.searchText = "paulista"
        #expect(viewModel.filteredPoints.count == 1)
        #expect(viewModel.filteredPoints.first?.name == "Home")

        viewModel.searchText = "office"
        #expect(viewModel.filteredPoints.count == 1)
        #expect(viewModel.filteredPoints.first?.name == "Office")
    }

    @Test func savingDuplicateNameWithoutOverwriteThrows() throws {
        let viewModel = try makeViewModel()
        try save(viewModel, name: "Home")
        #expect(throws: StorageError.self) {
            try save(viewModel, name: "Home")
        }
    }

    @Test func overwriteUpdatesCoordinate() throws {
        let viewModel = try makeViewModel()
        try save(viewModel, name: "Home", latitude: 1, longitude: 2)
        try save(viewModel, name: "Home", latitude: 10, longitude: 20, overwrite: true)
        #expect(viewModel.points.count == 1)
        #expect(viewModel.points.first?.latitude == 10)
        #expect(viewModel.points.first?.longitude == 20)
    }

    @Test func deleteRemovesPoint() throws {
        let viewModel = try makeViewModel()
        try save(viewModel, name: "Home")
        let point = try #require(viewModel.points.first)
        try viewModel.delete(point)
        #expect(viewModel.points.isEmpty)
    }

    @Test func sortsByLastUsedMostRecentFirst() throws {
        let viewModel = try makeViewModel()
        try save(viewModel, name: "First")
        try save(viewModel, name: "Second")
        // "Second" was inserted last, so it starts on top.
        #expect(viewModel.points.first?.name == "Second")

        // Touching "First" moves it to the top.
        let first = try #require(viewModel.points.first { $0.name == "First" })
        try viewModel.touch(first)
        #expect(viewModel.points.first?.name == "First")
    }
}
