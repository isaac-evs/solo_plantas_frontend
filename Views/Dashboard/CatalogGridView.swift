//
//  CatalogGridView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI

struct CatalogGridView: View {
    @EnvironmentObject var appState: AppState
    
    @StateObject private var viewModel = CatalogViewModel()
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.93).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header
                    HStack {
                        Text("Your Garden")
                            .font(.system(size: 36, weight: .bold, design: .serif))
                        Spacer()
                        Text("\(appState.unlockedPlantIDs.count) / \(viewModel.totalCatalogSize)")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Banner
                    SeasonalBanner(icon: "🍂", message: "3 plants blooming in Jalisco now")
                        .padding(.horizontal, 24)
                    
                    // Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.allPlants) { plant in
                            
                            let unlocked = viewModel.isUnlocked(plant: plant, in: appState.unlockedPlantIDs)
                            
                            CatalogCell(plant: plant, isUnlocked: unlocked) {
                                if unlocked {
                                    appState.currentScreen = .plantHome(plant)
                                } else {
                                    print("Locked: \(plant.name) teaser tapped.")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Button
                    PrimaryButton(title: "Already growing a native plant?", backgroundColor: .black) {
                        appState.currentScreen = .scan
                    }
                    .padding(24)
                }
            }
        }
    }
}

struct CatalogCell: View {
    let plant: PlantSpecies
    let isUnlocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Rectangle()
                    .fill(isUnlocked ? Color.white : Color.gray.opacity(0.2))
                    .frame(height: 140)
                    .overlay(
                        Group {
                            if !isUnlocked {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                    .font(.title)
                            } else {
                                Text(plant.name.prefix(1))
                                    .font(.system(size: 50, design: .serif))
                                    .foregroundColor(.green.opacity(0.3))
                            }
                        }
                    )
                
                Text(isUnlocked ? plant.name : "Unknown")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(isUnlocked ? .black : .gray)
                    .padding(.bottom, 8)
            }
            .background(isUnlocked ? Color.white : Color.clear)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(isUnlocked ? 0.05 : 0), radius: 5, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
