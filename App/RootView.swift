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
        Group {
            switch appState.currentScreen {
            case .opening:
                OpeningView()
            case .selection:
                PlantSelectionView()
            case .arGrowth(let plant):
                ARGrowthView(plant: plant)
            case .bridge(let plant):
                BridgeTransitionView(plant: plant)
            case .arGarden(let plant):
                ARGardenView(plant: plant)
            case .plantHome(let plant):
                PlantHomeView(plant: plant)
            case .catalog:
                CatalogGridView()
            case .scan:
                ScanView()
            }
        }
        
        .environmentObject(appState)
        .animation(.easeInOut, value: appState.currentScreen)
    }
}
