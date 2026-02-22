//
//  ARGardenView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 13/02/26.
//

import SwiftUI

struct ARGardenView: View {
    @EnvironmentObject var appState: AppState
    
    @StateObject private var viewModel: ARGardenViewModel
    
    init(plant: PlantSpecies) {
        _viewModel = StateObject(wrappedValue: ARGardenViewModel(plant: plant, isFullyGrown: true))
    }
    
    var body: some View {
        ZStack {
            ARViewContainer(viewModel: viewModel)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                PrimaryButton(title: "Explore", icon: "arrow.right", backgroundColor: Color.white.opacity(0.9), textColor: .black) {
                    appState.currentScreen = .plantHome(viewModel.plant)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
}
