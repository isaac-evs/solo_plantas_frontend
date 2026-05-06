//
//  AppState.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 13/02/26.
//

import SwiftUI

enum AppScreen: Equatable {
    case splash
    case login
    case signUp
    case onboarding
    case catalog
    case arGrowth(PlantSpecies)
    case bridge(PlantSpecies)
    case arGarden(PlantSpecies, Int?)
    case arPreview(PlantSpecies)
    case virtualGarden
    case profile
    case checkout(subtotal: Double)
    case plantHome
    case scan
    case plantUnlock(PlantSpecies)
    case assistant
    case driverDashboard
}

enum AppTab {
    case home
    case catalog
    case scan
    case profile
    case assistant
}

@MainActor
class AppState: ObservableObject {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    @Published var currentScreen: AppScreen = .splash
    @Published var activeTab: AppTab = .home
    @Published var focusedPlantID: String? = nil
    @Published var plantedDates: [String: Date] = [:] {
        didSet {
            PersistenceService.shared.saveGarden(plantedDates: plantedDates)
        }
    }
    
    @Published var selectedNurseryForPickup: String? = nil

    var showsTabBar: Bool {
        switch currentScreen {
        case .plantHome, .catalog, .scan, .profile, .assistant: return true
        default: return false
        }
    }

    init() {
        self.plantedDates = PersistenceService.shared.loadGarden()
    }

    func routeAfterSplash() {
        if KeychainHelper.shared.getToken() != nil {
            let isDriver = UserDefaults.standard.bool(forKey: "isDriverMode")
            if isDriver {
                currentScreen = .driverDashboard
            } else {
                currentScreen = .plantHome
            }
        } else {
            currentScreen = .login
        }
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
        case .profile: currentScreen = .profile
        case .assistant: currentScreen = .assistant
        }
    }
}
