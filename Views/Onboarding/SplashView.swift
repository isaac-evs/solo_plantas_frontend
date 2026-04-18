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
            GeometryReader { geo in
                Image("splash")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped() 
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                
                VStack(spacing: isIpad ? 24 : 16) {
                    
                    Text("Milpa")
                        .font(.system(size: isIpad ? 84 : 72, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.85), radius: 2, x: 0, y: 2)
                        .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 6)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Return native species to Jalisco.")
                        .font(.system(size: isIpad ? 34 : 20, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, isIpad ? 32 : 24)
                        .padding(.vertical, isIpad ? 16 : 12)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        )
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .frame(maxHeight: .infinity, alignment: .center)
                .opacity(isVisible ? 1.0 : 0.0)
                .scaleEffect(isVisible ? 1.0 : 0.95)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    isVisible = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    let feedback = UIImpactFeedbackGenerator(style: .soft)
                    feedback.impactOccurred()
                    
                    withAnimation(.easeInOut(duration: 0.5)) {
                        appState.routeAfterSplash()
                    }
                }
            }
        }
    }
}
