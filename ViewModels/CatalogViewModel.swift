//
//  CatalogViewModel.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import Foundation

@MainActor
class CatalogViewModel: ObservableObject {
    
    @Published var allPlants: [PlantSpecies] = []
    
    let totalCatalogSize = 15
    
    init() {
        loadCatalog()
    }
    
    private func loadCatalog() {
        self.allPlants = DataService.shared.catalog
    }
    
    func isUnlocked(plant: PlantSpecies, in unlockedIDs: Set<String>) -> Bool {
        return unlockedIDs.contains(plant.id)
    }
}
