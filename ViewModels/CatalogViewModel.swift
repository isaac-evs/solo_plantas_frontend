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
    @Published var selectedFilter: SeasonFilter = .spring

    var totalCatalogSize: Int {
        allPlants.count
    }
    
    var recommendedPlants: [PlantSpecies] {
        CatalogManager.shared.recommendedPlants
    }

    enum SeasonFilter: String, CaseIterable {
        case spring = "Spring"
        case summer = "Summer"
        case fall   = "Fall"
        case winter = "Winter"

        var seasonCategory: SeasonCategory {
            switch self {
            case .spring: return .spring
            case .summer: return .summer
            case .fall:   return .fall
            case .winter: return .winter
            }
        }

        var icon: String {
            switch self {
            case .spring: return "camera.macro"
            case .summer: return "sun.max"
            case .fall:   return "leaf"
            case .winter: return "snowflake"
            }
        }
    }

    var filteredPlants: [PlantSpecies] {
        allPlants.filter { $0.seasonCategory == selectedFilter.seasonCategory }
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

    init() { 
        Task { await loadCatalog() } 
    }

    func loadCatalog() async {
        do {
            try await CatalogManager.shared.fetchCatalog()
            try await CatalogManager.shared.fetchRecommendations()
            self.allPlants = CatalogManager.shared.cachedCatalog
        } catch {
            print("Error loading catalog: \(error)")
        }
    }
    
    func refresh() async {
        do {
            try await CatalogManager.shared.refresh()
            self.allPlants = CatalogManager.shared.cachedCatalog
        } catch {
            print("Error refreshing catalog: \(error)")
        }
    }
}
