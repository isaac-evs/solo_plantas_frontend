//
//  ARGrowthView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 20/02/26.
//

import SwiftUI
import RealityKit

struct ARGrowthView: View {
    @EnvironmentObject var appState : AppState
    let plant: PlantSpecies

    @State private var growthStage: Float = 0
    @State private var isPlanted: Bool = false
    
    var body: some View {
        ZStack{
            ARViewContainer(species: plant, growthStage: Int(growthStage), isPlanted: $isPlanted)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if isPlanted {
                    VStack(spacing: 8){
                        Text("Meet your \(plant.name)")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                        
                        Text(plant.ecologicalRole)
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
                
                if isPlanted {
                    VStack{
                        Slider(value: $growthStage, in: 1...4, step: 1)
                            .accentColor(.green)
                            .padding(.horizontal)
                        
                        Text("Stage \(Int(growthStage))")
                            .foregroundColor(.white)
                            .font(.caption)
                        
                        if growthStage == 4 {
                            Button(action: {
                                appState.unlockedPlantIDs.insert(plant.id)
                                appState.currentScreen = .bridge(plant)
                            }) {
                                HStack{
                                    Image(systemName: "camera.fill")
                                    Text("Capture & Add to Garden")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(red: 0.3, green: 0.5, blue: 0.3))
                                .cornerRadius(12)
                            }
                            .padding(.top, 10)
                            .transition(.move(edge: . bottom))
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(15)
                    .padding()
                }
            }
        }
        .animation(.easeInOut, value: isPlanted)
        .animation(.easeInOut, value: growthStage)
    }
}
