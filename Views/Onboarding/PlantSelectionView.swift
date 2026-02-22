//
//  PlantSelectionView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
//

import SwiftUI

struct PlantSelectionView: View {
    @EnvironmentObject var appState: AppState
    
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body : some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.93).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Pick your first native plant")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.2))
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        
                        ForEach(viewModel.starterPlants) { plant in
                            
                            WatercolorCard(
                                title: plant.name,
                                subtitle: plant.ecologicalRole,
                                illustrationName: plant.illustrationName
                            ) {
                                appState.currentScreen = .arGrowth(plant)
                            }
                            
                        }
                        
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                
                Spacer()
            }
        }
    }
}
