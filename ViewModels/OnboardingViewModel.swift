//
//  OnboardingViewModel.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    
    @Published var starterPlants: [PlantSpecies] = []
    
    init() {
        loadStarterPlants()
    }
    
    private func loadStarterPlants() {
        let allPlants = DataService.shared.catalog
        self.starterPlants = Array(allPlants.prefix(6))
    }
}
