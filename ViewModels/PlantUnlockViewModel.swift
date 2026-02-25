//
//  PlantUnlockViewModel.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 24/02/26.
//

import SwiftUI

enum PlantStage: String, CaseIterable {
    case seed     = "Seed"
    case sprout   = "Sprout"
    case small    = "Small"
    case juvenile = "Juvenile"
    case grown    = "Grown"

    var description: String {
        switch self {
        case .seed:     return "Just planted, beginning its journey"
        case .sprout:   return "First leaves emerging from the soil"
        case .small:    return "Establishing roots, growing steadily"
        case .juvenile: return "Strong and branching, nearly there"
        case .grown:    return "Fully matured, ready to thrive"
        }
    }

    var icon: String {
        switch self {
        case .seed:     return "circle.dotted"
        case .sprout:   return "leaf"
        case .small:    return "leaf.fill"
        case .juvenile: return "tree"
        case .grown:    return "camera.macro"
        }
    }

    // Maps stage to a planted date in the past so the growth math
    // in PlantHomeViewModel produces the right iteration immediately
    func simulatedPlantedDate(for plant: PlantSpecies) -> Date {
        guard plant.growthMilestones.count >= 4 else { return Date() }
        let m = plant.growthMilestones
        let daysAgo: Int
        switch self {
        case .seed:     daysAgo = 0
        case .sprout:   daysAgo = m[0]           // just hit first milestone
        case .small:    daysAgo = m[1]           // just hit second milestone
        case .juvenile: daysAgo = m[2]           // just hit third milestone
        case .grown:    daysAgo = m[3]           // fully matured
        }
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    }
}

@MainActor
class PlantUnlockViewModel: ObservableObject {
    let plant: PlantSpecies
    @Published var selectedStage: PlantStage = .seed
    @Published var isConfirming = false

    init(plant: PlantSpecies) {
        self.plant = plant
    }

    func confirm(appState: AppState) {
        isConfirming = true
        let backdatedDate = selectedStage.simulatedPlantedDate(for: plant)

        // Override the planted date with the back-calculated one
        appState.plantedDates[plant.id] = backdatedDate
        appState.focusedPlantID = plant.id
    }
}
