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

    @State private var showMap       = false
    @State private var showGuide     = false
    @State private var appeared      = false

    private let t: SeedPacketTheme

    init(plant: PlantSpecies) {
        self.plant = plant
        self.t = seedTheme(for: plant.id)
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [t.background, t.background.opacity(0.6), Color(hex: "#F0EBE0")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Text(String(plant.name.prefix(1)))
                .font(.system(size: 320, weight: .black, design: .serif))
                .foregroundColor(t.patternColor.opacity(0.09))
                .offset(x: 80, y: -40)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // --- Plant Badge ---
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(t.patternColor.opacity(0.18))
                            .frame(width: 110, height: 110)
                        Circle()
                            .strokeBorder(t.accent.opacity(0.25), lineWidth: 1.5)
                            .frame(width: 110, height: 110)
                        Image(plant.illustrationName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 76, height: 76)
                    }
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: 6) {
                        Text("YOU GREW")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(5)
                            .foregroundColor(t.accent.opacity(0.7))

                        Text(plant.name)
                            .font(.system(size: 38, weight: .bold, design: .serif))
                            .foregroundColor(t.textColor)

                        Text(plant.scientificName)
                            .font(.system(size: 13, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(t.textColor.opacity(0.45))
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                }

                HStack {
                    Rectangle()
                        .fill(t.accent.opacity(0.15))
                        .frame(height: 1)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 10))
                        .foregroundColor(t.accent.opacity(0.4))
                    Rectangle()
                        .fill(t.accent.opacity(0.15))
                        .frame(height: 1)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 32)
                .opacity(appeared ? 1 : 0)

                // --- Options ---
                VStack(spacing: 8) {
                    Text("Ready to grow one for real?")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(t.textColor)
                        .multilineTextAlignment(.center)

                    Text("Find a seed nearby or learn how to plant it — your virtual and real \(plant.name) can grow together.")
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(t.textColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                Spacer()

                // ---  Cards ---
                VStack(spacing: 12) {
                    bridgeActionCard(
                        icon: "mappin.circle.fill",
                        title: "Find seeds nearby",
                        subtitle: "Nurseries in Jalisco that carry \(plant.name)",
                        filled: true
                    ) { showMap = true }

                    bridgeActionCard(
                        icon: "book.fill",
                        title: "How to plant it",
                        subtitle: "Step-by-step guide for your \(plant.name)",
                        filled: false
                    ) { showGuide = true }
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                // Continue button
                Button {
                    appState.currentScreen = .arGarden(plant)
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue to my garden")
                            .font(.system(size: 15, weight: .semibold, design: .serif))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(t.textColor.opacity(0.55))
                    .padding(.vertical, 18)
                }
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showMap)   { NurseryMapView() }
        .sheet(isPresented: $showGuide) { PlantingGuideView(plant: plant) }
    }

    private func bridgeActionCard(
        icon: String,
        title: String,
        subtitle: String,
        filled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(filled ? t.accent : t.accent.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(filled ? t.background : t.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundColor(t.textColor)
                    Text(subtitle)
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(t.textColor.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(t.textColor.opacity(0.3))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(filled ? t.accent.opacity(0.08) : Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(t.accent.opacity(filled ? 0.3 : 0.12), lineWidth: 1)
                    )
            )
        }
    }
}
