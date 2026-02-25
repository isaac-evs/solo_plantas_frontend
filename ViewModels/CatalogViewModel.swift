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
    @Published var selectedFilter: SeasonFilter = .all

    var totalCatalogSize: Int {
        allPlants.count
    }

    enum SeasonFilter: String, CaseIterable {
        case all    = "All"
        case spring = "Spring"
        case summer = "Summer"
        case fall   = "Fall"
        case winter = "Winter"

        var seasonCategory: SeasonCategory? {
            switch self {
            case .all:    return nil
            case .spring: return .spring
            case .summer: return .summer
            case .fall:   return .fall
            case .winter: return .winter
            }
        }

        var icon: String {
            switch self {
            case .all:    return "square.grid.2x2"
            case .spring: return "flower"
            case .summer: return "sun.max"
            case .fall:   return "leaf"
            case .winter: return "snowflake"
            }
        }
    }

    var filteredPlants: [PlantSpecies] {
        guard let category = selectedFilter.seasonCategory else { return allPlants }
        return allPlants.filter { $0.seasonCategory == category }
    }

    var availableThisSeason: [PlantSpecies] {
        let month = Calendar.current.component(.month, from: Date())
        let currentSeason: SeasonCategory
        switch month {
        case 3...5:  currentSeason = .spring
        case 6...8:  currentSeason = .summer
        case 9...11: currentSeason = .fall
        default:     currentSeason = .winter
        }
        return allPlants.filter { $0.seasonCategory == currentSeason }
    }

    init() { loadCatalog() }

    private func loadCatalog() {
        self.allPlants = DataService.shared.catalog
    }
}
