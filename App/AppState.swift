//
//  AppState.swift
//  VirtualGarden
//

import SwiftUI

enum AppScreen: Equatable {
    case splash
    case onboarding
    case catalog
    case arGrowth(PlantSpecies)
    case bridge(PlantSpecies)
    case arGarden(PlantSpecies)
    case plantHome
    case scan
    case plantUnlock(PlantSpecies)  // ← added
}

@MainActor
class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .splash
    @Published var focusedPlantID: String? = nil
    @Published var plantedDates: [String: Date] = [:] {
        didSet {
            PersistenceService.shared.saveGarden(plantedDates: plantedDates)
        }
    }

    init() {
        // --------- TESTING ONLY -------- //
        // UserDefaults.standard.removeObject(forKey: "virtual_garden_save_data")
        // ------------------------------- //
        self.plantedDates = PersistenceService.shared.loadGarden()
    }

    func routeAfterSplash() {
        currentScreen = plantedDates.isEmpty ? .onboarding : .plantHome
    }

    func plantSeed(for speciesID: String) {
        if plantedDates[speciesID] == nil {
            plantedDates[speciesID] = Date()
        }
    }

    func plantSeed(for speciesID: String, on date: Date) {
        plantedDates[speciesID] = date
    }

    func navigateToPlanHomeCard(plantID: String) {
        focusedPlantID = plantID
        currentScreen = .plantHome
    }
}
