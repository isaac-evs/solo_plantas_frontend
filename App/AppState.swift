//
//  AppState.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 13/02/26.
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
    case plantUnlock(PlantSpecies)
}

enum AppTab {
    case home
    case catalog
    case scan
}

@MainActor
class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .splash
    @Published var activeTab: AppTab = .home
    @Published var focusedPlantID: String? = nil
    @Published var plantedDates: [String: Date] = [:] {
        didSet {
            PersistenceService.shared.saveGarden(plantedDates: plantedDates)
        }
    }

    var showsTabBar: Bool {
        switch currentScreen {
        case .plantHome, .catalog, .scan: return true
        default: return false
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
        activeTab = .home
    }

    func switchTab(_ tab: AppTab) {
        activeTab = tab
        switch tab {
        case .home:    currentScreen = .plantHome
        case .catalog: currentScreen = .catalog
        case .scan:    currentScreen = .scan
        }
    }
}
