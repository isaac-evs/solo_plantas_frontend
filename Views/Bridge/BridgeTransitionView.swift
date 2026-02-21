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
                
                VStack(spacing: 16){
                    // Map button
                    ActionButton(icon: "mappin.circle.fill", text: "Find seeds or plants nearby"){
                        showMap = true
                    }
                    
                    // Guide button
                    ActionButton(icon: "book.fill", text: "Learn how to plant it"){
                        showGuide = true
                    }
                    
                    // Skip button
                    Button(action: {
                        appState.currentScreen = .plantHome(plant)
                    }) {
                        HStack {
                            Image(systemName: "leaf.arrow.circlepath")
                            Text("I'll get it later")
                        }
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
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
        
        // Map sheet
        .sheet(isPresented: $showMap){
            NurseryMapView()
        }
        .sheet(isPresented: $showGuide) {
            PlantingGuideView(plant: plant)
        }
    }
}
        
struct ActionButton: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action){
            HStack(spacing: 15){
                Image(systemName: icon)
                    .font(.title2)
                Text(text)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .opacity(0.5)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.3, green: 0.5, blue: 0.3))
            .cornerRadius(12)
        }
    }
}

