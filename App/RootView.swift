//
//  RootView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 13/02/26.
//

import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        ZStack(alignment: .bottom) {

            ZStack {
                switch appState.currentScreen {
                case .splash:                 SplashView()
                case .login:                  LoginView()
                case .signUp:                 SignUpView()
                case .onboarding:             PlantSelectionView()
                case .plantHome:              PlantHomeView()
                case .catalog:                CatalogGridView()
                case .scan:                   ScanView()
                case .arGrowth(let plant):    ARGrowthView(plant: plant)
                case .bridge(let plant):      BridgeTransitionView(plant: plant)
                case .arGarden(let plant):    ARGardenView(plant: plant)
                case .virtualGarden:          VirtualGardenView()
                case .checkout(let amount):   CheckoutView(subtotal: amount)
                case .profile:                ProfileView()
                case .assistant:              ChatbotView()
                case .plantUnlock(let plant): PlantUnlockView(plant: plant)
                }
            }
            .ignoresSafeArea()

            if appState.showsTabBar {
                MainTabBar()
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal:   .move(edge: .bottom).combined(with: .opacity)
                        )
                    )
                    .padding(.bottom, 12)
            }
        }
        .environmentObject(appState)
        .environmentObject(CartManager.shared)
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: appState.showsTabBar)
        .animation(.easeInOut(duration: 0.35), value: appState.currentScreen)
    }
}
