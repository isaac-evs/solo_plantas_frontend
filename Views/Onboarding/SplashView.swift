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
    
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.93).ignoresSafeArea()
            
            VStack(spacing: isIpad ? 30 : 20) {
                Image(systemName: "leaf.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: isIpad ? 140 : 100, height: isIpad ? 140 : 100)
                    .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.2))
                    .accessibilityHidden(true)
                
                Text("Virtual Garden")
                    .font(.system(size: isIpad ? 54 : 36, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.2))
                
                Text("Return native species to Jalisco.")
                    .font(.system(size: isIpad ? 24 : 18, weight: .regular, design: .serif))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer().frame(height: isIpad ? 60 : 40)
                
                Button {
                    let feedback = UIImpactFeedbackGenerator(style: .medium)
                    feedback.impactOccurred()
                    
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appState.routeAfterSplash()
                    }
                } label: {
                    Text("Tap to Begin")
                        .font(.system(size: isIpad ? 22 : 18, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                        .padding(.horizontal, isIpad ? 40 : 32)
                        .padding(.vertical, isIpad ? 20 : 16)
                        .background(Color(red: 0.2, green: 0.4, blue: 0.2))
                        .clipShape(Capsule())
                }
                .accessibilityHint("Starts your journey to restore the garden")
            }
            .opacity(isVisible ? 1.0 : 0.0)
            .scaleEffect(isVisible ? 1.0 : 0.95)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                isVisible = true
            }
        }
    }
}
