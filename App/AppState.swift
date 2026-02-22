//
//  AppState.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
//

import SwiftUI

enum AppScreen: Equatable {
    case opening
    case selection
    case arGrowth(PlantSpecies)
    case bridge(PlantSpecies)
    case arGarden(PlantSpecies)
    case plantHome(PlantSpecies)
    case catalog
    case scan
}

@MainActor
class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .opening
    @Published var unlockedPlantIDs : Set<String> = []{
        didSet{
            PersistenceService.shared.saveGarden(plantIDs: unlockedPlantIDs)
        }
    }
    
    init(){
        
        // --------- TESTING ONLY -------- //
        
        UserDefaults.standard.removeObject(forKey: "virtual_garden_save_data")
        
        // ------------------------------- //
        
        self.unlockedPlantIDs = PersistenceService.shared.loadGarden()
    }
}
