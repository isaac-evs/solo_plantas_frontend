//
//  SplashView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appState: AppState
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.93).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Splash
                Image(systemName: "leaf.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.2))
                
                Text("Virtual Garden")
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.2))
                
                Text("Return native species to Jalisco.")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundColor(.gray)
            }
            .opacity(isVisible ? 1.0 : 0.0)
            .scaleEffect(isVisible ? 1.0 : 0.95)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                isVisible = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                appState.routeAfterSplash()
            }
        }
    }
}
