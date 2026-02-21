//
//  PlantSelectionView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
//

import SwiftUI;

struct PlantSelectionView: View {
    @EnvironmentObject var appState: AppState
    
    let plants = Array(DataService.shared.catalog.prefix(3))
    
    var body : some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.93).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20){
                Text("Pick your first native plant")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.2))
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                
                ScrollView(.horizontal, showsIndicators: false){
                    HStack(spacing: 20){
                        ForEach(plants) { plant in
                            PlantCard(plant: plant){
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

struct PlantCard : View {
    let plant: PlantSpecies
    let action: () -> Void
    
    var body: some View {
        Button(action: action){
            VStack(alignment: .leading, spacing: 12) {
                
                // Placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 220)
                    .cornerRadius(12)
                    .overlay(Text(plant.illustrationName).foregroundColor(.gray))
                                
                    Text(plant.name)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(.black)
                                
                    Text(plant.ecologicalRole)
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                                
                    Spacer()
                }
                .padding(16)
                .frame(width: 260, height: 300)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.08), radius: 15, x:0, y:10)
            }
    .buttonStyle(PlainButtonStyle())
    }
}

