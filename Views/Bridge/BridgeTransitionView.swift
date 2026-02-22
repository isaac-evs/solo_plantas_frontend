//
//  BridgeTransitionView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI

struct BridgeTransitionView: View {
    @EnvironmentObject var appState: AppState
    let plant: PlantSpecies
    
    @State private var showMap = false
    @State private var showGuide = false
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.93).ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Text("Ready to grow\n\(plant.name) in real life?")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.2))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    // Map Button
                    PrimaryButton(title: "Find seeds or plants nearby", icon: "mappin.circle.fill") {
                        showMap = true
                    }
                    
                    // Guide Button
                    PrimaryButton(title: "Learn how to plant it", icon: "book.fill") {
                        showGuide = true
                    }
                    
                    // Skip Button
                    PrimaryButton(
                        title: "I'll get it later",
                        icon: "leaf.arrow.circlepath",
                        backgroundColor: .clear,
                        textColor: .gray
                    ) {
                        appState.currentScreen = .arGarden(plant)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Text("Your virtual garden is waiting.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom)
            }
        }
        .sheet(isPresented: $showMap) {
            NurseryMapView()
        }
        .sheet(isPresented: $showGuide) {
            PlantingGuideView(plant: plant)
        }
    }
}
