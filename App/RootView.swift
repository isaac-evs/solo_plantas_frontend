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
            case .plantHome(let plant):
                Text("Home Placeholder for: \(plant.name)")
            case .catalog:
                Text("Catalog Placeholder")
            }
        }
        
        .environmentObject(appState)
        .animation(.easeInOut, value: appState.currentScreen)
    }
}
