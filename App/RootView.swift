//
//  RootView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 13/02/26.
//

import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        ZStack {
            switch appState.currentScreen {
            case .splash:
                SplashView()
            case .onboarding:
                PlantSelectionView()
            case .catalog:
                CatalogGridView()
            case .arGrowth(let plant):
                ARGrowthView(plant: plant)
            case .bridge(let plant):
                BridgeTransitionView(plant: plant)
            case .arGarden(let plant):
                ARGardenView(plant: plant)
            case .plantHome:
                PlantHomeView()
            case .scan:
                ScanView()
            case .plantUnlock(let plant):
                PlantUnlockView(plant: plant)
            }
        }
        .environmentObject(appState)
        .animation(.easeInOut(duration: 0.5), value: appState.currentScreen)
    }
}
