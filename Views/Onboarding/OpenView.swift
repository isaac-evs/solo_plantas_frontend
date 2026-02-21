//
//  OpenView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
//

import SwiftUI;

struct OpeningView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue:0.93).ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(Text("Splash Screen"))
                
                Text("Virtual Garden")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundColor(.gray)
                    .padding(.top, 4)
                
                Spacer()
                
                Button(action: {
                    appState.currentScreen = .selection
                }) {
                    Text("Begin")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.3, green: 0.5, blue:0.3))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}
