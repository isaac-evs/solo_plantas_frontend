//
//  OpenView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
//

import SwiftUI

struct OpeningView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.93).ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(Text("Splash Screen Illustration"))
                    .padding()
                
                Text("Virtual Garden")
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.2))
                
                Text("Return native species to Jalisco.")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundColor(.gray)
                    .padding(.top, 4)
                
                Spacer()
                
                PrimaryButton(title: "Begin") {
                    appState.currentScreen = .selection
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}
