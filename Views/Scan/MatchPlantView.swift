//
//  MatchPlantView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI

struct MatchPlantView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    let matchedPlants: [PlantSpecies]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.93).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text(matchedPlants.isEmpty ? "No Match Found" : "Match Found")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .padding(.horizontal)
                        .padding(.top)
                    
                    if matchedPlants.isEmpty {
                        // Handle Edge Case
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "leaf.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("We couldn't find a matching native species for that color in your locked catalog.")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Spacer()
                        }
                    } else {
                        // Success
                        Text("Which of these native species are you growing?")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        ScrollView {
                            VStack(spacing: 15) {
                                ForEach(matchedPlants) { plant in
                                    Button(action: {
                                        // Unlock it
                                        appState.unlockedPlantIDs.insert(plant.id)
                                        dismiss()
                                        // Return to catalog
                                        appState.currentScreen = .catalog
                                    }) {
                                        HStack {
                                            Circle()
                                                .fill(Color.green.opacity(0.2))
                                                .frame(width: 50, height: 50)
                                                .overlay(Text(plant.name.prefix(1)).foregroundColor(.green))
                                            
                                            VStack(alignment: .leading) {
                                                Text(plant.name)
                                                    .font(.headline)
                                                    .foregroundColor(.black)
                                                Text(plant.scientificName)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                    .italic()
                                            }
                                            Spacer()
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.title2)
                                        }
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}
