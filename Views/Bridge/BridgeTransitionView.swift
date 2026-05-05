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

    @State private var appeared   = false
    @State private var showNurseryMap = false
    @State private var showPlantDetail = false

    @Environment(\.accessibilityReduceMotion)       private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let t: SeedPacketTheme
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    
    private var s: CGFloat { isIpad ? 1.8 : 1.25 }

    init(plant: PlantSpecies) {
        self.plant = plant
        self.t     = seedTheme(for: plant.id)
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [t.background, t.background.opacity(0.7), Color(hex: "#F0EBE0")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 40)

                        // --- Plant badge ---
                        VStack(spacing: 20) {
                            
                            let outerSize: CGFloat = isIpad ? 180 : 140
                            let imageSize: CGFloat = isIpad ? 150 : 116
                            
                            ZStack {
                                Circle()
                                    .fill(t.patternColor.opacity(0.18))
                                    .frame(width: outerSize, height: outerSize)
                                Circle()
                                    .strokeBorder(t.accent.opacity(0.22), lineWidth: 1.5)
                                    .frame(width: outerSize, height: outerSize)
                                
                                Image(plant.illustrationName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: imageSize, height: imageSize)
                                    .clipShape(Circle())
                                    .accessibilityLabel("\(plant.name) illustration")
                            }
                            .scaleEffect(appeared ? 1 : 0.65)
                            .opacity(appeared ? 1 : 0)
                            .accessibilityHidden(false)

                            VStack(spacing: 10) {
                                Text("DAY 0: SEED PLANTED")
                                    .font(.system(size: 14 * s, weight: .bold))
                                    .tracking(4)
                                    .foregroundColor(t.accent)
                                    .multilineTextAlignment(.center)
                                    .accessibilityAddTraits(.isHeader)

                                Text(plant.name)
                                    .font(.system(size: 46 * s, weight: .bold))
                                    .foregroundColor(t.textColor)
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                        }
                        .padding(.horizontal, 24)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(plant.name) seed successfully planted. Day 0 begins.")

                        Spacer().frame(height: isIpad ? 80 : 50)

                        // --- Explanation  ---
                        VStack(spacing: 20) {
                            Text("The Real Journey Begins")
                                .font(.system(size: 26 * s, weight: .bold))
                                .foregroundColor(t.textColor)
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)

                            Text("You just saw a vision of the future. In reality, native plants require patience. It will take \(plant.growthMilestones.last ?? 30) real-world days for your virtual seed to reach maturity.")
                                .font(.system(size: 18 * s, weight: .medium))
                                .foregroundColor(t.textColor.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                        }
                        .padding(.horizontal, isIpad ? 80 : 36)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        
                        Spacer().frame(height: isIpad ? 80 : 50)

                        // --- Action Buttons ---
                        VStack(spacing: 16) {
                            
                            // Primary Button
                            Button {
                                appState.hasSeenOnboarding = true
                                if KeychainHelper.shared.getToken() != nil {
                                    appState.currentScreen = .plantHome
                                } else {
                                    appState.currentScreen = .signUp
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Text("Go to my garden")
                                        .font(.system(size: 20 * s, weight: .semibold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 18, weight: .semibold))
                                        .accessibilityHidden(true)
                                }
                                .foregroundColor(t.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: isIpad ? 80 : 70)
                                .background(t.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                            .accessibilityLabel("Go to my garden or create account")
                            
                            // Secondary Action Buttons
                            HStack(spacing: 16) {
                                // Where to get it
                                Button {
                                    showNurseryMap = true
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 18 * s, weight: .medium))
                                        Text("Where to get it")
                                            .font(.system(size: 13 * s, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .foregroundColor(t.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(t.accent.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                }
                                .accessibilityLabel("Find nearby nurseries to get this plant")

                                // How to plant it
                                Button {
                                    showPlantDetail = true
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "leaf.fill")
                                            .font(.system(size: 18 * s, weight: .medium))
                                        Text("How to plant it")
                                            .font(.system(size: 13 * s, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .foregroundColor(t.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(t.accent.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                }
                                .accessibilityLabel("Read care and planting instructions")
                            }
                        }
                        .padding(.horizontal, isIpad ? 80 : 28)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        
                        Spacer(minLength: 40)
                    }
                    .frame(minHeight: geo.size.height)
                }
            }
        }
        .sheet(isPresented: $showNurseryMap) {
            NurseryMapView()
        }
        .sheet(isPresented: $showPlantDetail) {
            PlantDetailView(plant: plant)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            withAnimation(
                reduceMotion
                    ? .none
                    : .spring(response: 0.6, dampingFraction: 0.75).delay(0.15)
            ) { appeared = true }
        }
    }
}
