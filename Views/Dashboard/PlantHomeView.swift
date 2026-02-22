//
//  PlantHomeView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI

struct PlantHomeView: View {
    @EnvironmentObject var appState: AppState
    let plant: PlantSpecies
    
    @State private var showMap = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Top Card
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(Color(red: 0.9, green: 0.92, blue: 0.9))
                        .frame(height: 350)
                        .overlay(Text("AR Screenshot / Illustration").foregroundColor(.gray))
                    
                    VStack(alignment: .leading) {
                        Text(plant.name)
                            .font(.system(size: 40, weight: .bold, design: .serif))
                        Text(plant.scientificName)
                            .font(.system(size: 18, design: .serif))
                            .italic()
                            .opacity(0.8)
                    }
                    .padding()
                }
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.top)
                
                // Text
                Text(plant.description)
                    .font(.system(size: 20, design: .serif))
                    .padding(.horizontal, 24)
                
                Divider().padding(.horizontal)
                
                // Details
                VStack(spacing: 16) {
                    DetailRow(icon: "leaf.fill", title: "Ecosystem Role", text: plant.ecologicalRole)
                    DetailRow(icon: "sun.max.fill", title: "Season", text: plant.season)
                }
                .padding(.horizontal, 24)
                
                // Button
                PrimaryButton(title: "Where to get \(plant.name)", icon: "mappin.and.ellipse") {
                    showMap = true
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                // Button
                PrimaryButton(
                    title: "View My Garden Catalog",
                    backgroundColor: Color.green.opacity(0.1),
                    textColor: Color(red: 0.3, green: 0.5, blue: 0.3)
                ) {
                    appState.currentScreen = .catalog
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(red: 0.98, green: 0.97, blue: 0.95).ignoresSafeArea())
        .sheet(isPresented: $showMap) {
            NurseryMapView()
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                Text(text)
                    .font(.system(size: 16, design: .serif))
            }
            Spacer()
        }
    }
}
