//
//  ARGardenViewModel.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI

@MainActor
class ARGardenViewModel: ObservableObject {
    
    // Data
    let plant: PlantSpecies
    
    // State
    @Published var isPlanted: Bool
    @Published var growthStage: Float
    
    var currentStageInt: Int {
        return Int(growthStage)
    }
    
    // Slect view
    init(plant: PlantSpecies, isFullyGrown: Bool = false) {
        self.plant = plant
        
        if isFullyGrown {
            self.isPlanted = true
            self.growthStage = 4.0
        } else {
            self.isPlanted = false
            self.growthStage = 1.0
        }
    }
    
    // AR Coordinator
    func markAsPlanted() {
        if !isPlanted {
            isPlanted = true
        }
    }
}
