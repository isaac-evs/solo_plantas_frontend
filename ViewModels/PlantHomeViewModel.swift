//
//  PlantHomeViewModel.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 23/02/26.
//

import Foundation
import SwiftUI

struct PlantGrowthStatus: Identifiable {
    let plant: PlantSpecies
    let daysElapsed: Int
    let currentIteration: Int
    let stageName: String
    let daysUntilNextStage: Int?
    
    var id: String { plant.id }
}

@MainActor
class PlantHomeViewModel: ObservableObject {
    @Published var userGarden: [PlantGrowthStatus] = []
    
    func loadGarden(from plantedDates: [String: Date]) {
        var statuses: [PlantGrowthStatus] = []
        
        for (id, date) in plantedDates {
            if let plant = DataService.shared.getPlant(by: id) {
                // Calculate days
                let elapsed = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
                
                let (iteration, stage, nextMilestone) = calculateStage(elapsedDays: elapsed, milestones: plant.growthMilestones)
                
                let daysRemaining = nextMilestone != nil ? (nextMilestone! - elapsed) : nil
                
                let status = PlantGrowthStatus(
                    plant: plant,
                    daysElapsed: elapsed,
                    currentIteration: iteration,
                    stageName: stage,
                    daysUntilNextStage: daysRemaining
                )
                statuses.append(status)
            }
        }
        
        // Sort by Oldest plant
        self.userGarden = statuses.sorted { $0.daysElapsed > $1.daysElapsed }
    }
    
    // State math
    private func calculateStage(elapsedDays: Int, milestones: [Int]) -> (Int, String, Int?) {
        guard milestones.count >= 4 else { return (1, "Just Planted", nil) }
        
        if elapsedDays >= milestones[3] {
            return (4, "Ready for Soil", nil)
        } else if elapsedDays >= milestones[2] {
            return (4, "Juvenile", milestones[3]) 
        } else if elapsedDays >= milestones[1] {
            return (3, "Small Sprout", milestones[2])
        } else if elapsedDays >= milestones[0] {
            return (2, "Sprout", milestones[1])
        } else {
            return (1, "Just Planted", milestones[0])
        }
    }
}
