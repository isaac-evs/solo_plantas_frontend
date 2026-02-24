//
//  AppState.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
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
}

@MainActor
class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .splash
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
        if plantedDates.isEmpty {
            currentScreen = .onboarding
        } else {
            currentScreen = .plantHome
        }
    }
    
    func plantSeed(for speciesID: String) {
        if plantedDates[speciesID] == nil {
            plantedDates[speciesID] = Date()
        }
    }
}
