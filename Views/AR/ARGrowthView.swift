//
//  ARGrowthView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 20/02/26.
//

import SwiftUI

struct ARGrowthView: View {
    @EnvironmentObject var appState: AppState
    
    @StateObject private var viewModel: ARGardenViewModel
    
    init(plant: PlantSpecies) {
        _viewModel = StateObject(wrappedValue: ARGardenViewModel(plant: plant, isFullyGrown: false))
    }
    
    var body: some View {
        ZStack {
            ARViewContainer(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if viewModel.isPlanted {
                    VStack(spacing: 8) {
                        Text("Meet your \(viewModel.plant.name)")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                        
                        Text(viewModel.plant.ecologicalRole)
                            .font(.system(size: 16, design: .serif))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .shadow(radius: 4)
                    }
                    .padding(.top, 50)
                    .transition(.opacity)
                } else {
                    Text("Tap the floor to plant the seed")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.top, 50)
                }
                
                Spacer()
                
                if viewModel.isPlanted {
                    VStack {
                        Slider(value: $viewModel.growthStage, in: 2...6, step: 1)
                            .accentColor(.green)
                            .padding(.horizontal)
                        
                        Text("Stage \(viewModel.currentStageInt)")
                            .foregroundColor(.white)
                            .font(.caption)
                        
                        if viewModel.currentStageInt == 4 {
                            PrimaryButton(title: "Capture & Add to Garden", icon: "camera.fill") {
                                appState.unlockedPlantIDs.insert(viewModel.plant.id)
                                appState.currentScreen = .bridge(viewModel.plant)
                            }
                            .padding(.top, 10)
                            .transition(.move(edge: .bottom))
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(15)
                    .padding()
                }
            }
        }
        .animation(.easeInOut, value: viewModel.isPlanted)
        .animation(.easeInOut, value: viewModel.growthStage)
    }
}
