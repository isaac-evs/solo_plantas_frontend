//
//  MatchPlantView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI

struct MatchPlantView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    let matchedPlants: [PlantSpecies]

    private let green = Color(hex: "#4A7C59")
    private let text  = Color(hex: "#1A2E1A")
    private let bg    = Color(hex: "#F5F0E8")

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {

                // Handle
                Capsule()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 48, height: 6)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                if matchedPlants.isEmpty {
                    emptyState
                } else {
                    successState
                }
            }
        }
    }

    // No Match Found
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "#D8D4CC").opacity(0.4))
                    .frame(width: 100, height: 100)
                Image(systemName: "leaf.circle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Color(hex: "#A0998F"))
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("NO MATCH FOUND")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .foregroundColor(green.opacity(0.8))
                    .accessibilityAddTraits(.isHeader)

                Text("Color not recognized")
                    .font(.system(size: 35, weight: .bold, design: .serif))
                    .foregroundColor(text)

                Text("We couldn't find a native species matching that color in your locked catalog. Try scanning a clearer leaf or flower in good lighting.")
                    .font(.system(size: 19, design: .serif))
                    .foregroundColor(text.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            Button { dismiss() } label: {
                Text("Try Again")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(green)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .accessibilityLabel("Try scanning again")
        }
    }

    // Match Found
    private var successState: some View {
        VStack(spacing: 0) {

            // Header
            VStack(spacing: 8) {
                Text("MATCH FOUND")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .foregroundColor(green.opacity(0.8))
                    .accessibilityAddTraits(.isHeader)
                
                Text("Which plant are you growing?")
                    .font(.system(size: 35, weight: .bold, design: .serif))
                    .foregroundColor(text)
                    .multilineTextAlignment(.center)
                
                Text("Select the one that matches your plant")
                    .font(.system(size: 18, design: .serif))
                    .foregroundColor(text.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
            .accessibilityElement(children: .combine)

            // Plant list
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(matchedPlants) { plant in
                        let t = seedTheme(for: plant.id)
                        Button {
                            appState.plantSeed(for: plant.id)
                            dismiss()
                            appState.currentScreen = .plantUnlock(plant)
                        } label: {
                            HStack(spacing: 20) {
                                let imgSize: CGFloat = 60
                                
                                ZStack {
                                    Circle()
                                        .fill(t.patternColor.opacity(0.2))
                                        .frame(width: imgSize + 12, height: imgSize + 12)
                                    
                                    Image(plant.illustrationName)
                                        .resizable()
                                        .scaledToFill() 
                                        .frame(width: imgSize, height: imgSize)
                                        .clipShape(Circle())
                                }
                                .accessibilityHidden(true)

                                // Info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plant.name)
                                        .font(.system(size: 24, weight: .bold, design: .serif))
                                        .foregroundColor(t.textColor)
                                    
                                }

                                Spacer()

                                // Indicator
                                ZStack {
                                    Circle()
                                        .fill(t.accent.opacity(0.12))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(t.accent)
                                }
                                .accessibilityHidden(true)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(t.background)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .strokeBorder(t.accent.opacity(0.18), lineWidth: 1.5)
                                    )
                                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                            )
                        }
                        .accessibilityLabel("Select \(plant.name)")
                        .accessibilityHint("Adds this plant to your garden")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            // Cancel
            Button { dismiss() } label: {
                Text("Cancel")
                    .font(.system(size: 19, weight: .medium, design: .serif))
                
                    .foregroundColor(text.opacity(0.5))
                    .padding(.vertical, 20)
            }
            .padding(.bottom, 20)
            .accessibilityLabel("Cancel selection")
        }
    }
}
