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

            // Faint letter watermark
            Text(matchedPlants.isEmpty ? "?" : String(matchedPlants[0].name.prefix(1)))
                .font(.system(size: 220, weight: .black, design: .serif))
                .foregroundColor(green.opacity(0.05))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 30, y: 30)
                .allowsHitTesting(false)

            VStack(spacing: 0) {

                // Handle
                Capsule()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 24)

                if matchedPlants.isEmpty {
                    emptyState
                } else {
                    successState
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "#D8D4CC").opacity(0.4))
                    .frame(width: 80, height: 80)
                Image(systemName: "leaf.circle")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(Color(hex: "#A0998F"))
            }

            VStack(spacing: 8) {
                Text("NO MATCH FOUND")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .foregroundColor(green.opacity(0.6))

                Text("Color not recognized")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(text)

                Text("We couldn't find a native species matching that color in your locked catalog. Try scanning a clearer leaf or flower in good lighting.")
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(text.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button { dismiss() } label: {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(green)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Success state

    private var successState: some View {
        VStack(spacing: 0) {

            // Header
            VStack(spacing: 6) {
                Text("MATCH FOUND")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .foregroundColor(green.opacity(0.7))
                Text("Which plant are you growing?")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(text)
                Text("Select the one that matches your plant")
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(text.opacity(0.5))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)

            // Plant list
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(matchedPlants) { plant in
                        let t = seedTheme(for: plant.id)
                        Button {
                            appState.plantSeed(for: plant.id)
                            dismiss()
                            appState.currentScreen = .plantUnlock(plant)
                        } label: {
                            HStack(spacing: 16) {
                                // Illustration
                                ZStack {
                                    Circle()
                                        .fill(t.patternColor.opacity(0.2))
                                        .frame(width: 56, height: 56)
                                    Image(plant.illustrationName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 42, height: 42)
                                }

                                // Info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plant.name)
                                        .font(.system(size: 17, weight: .bold, design: .serif))
                                        .foregroundColor(t.textColor)
                                    Text(plant.scientificName)
                                        .font(.system(size: 12, design: .serif))
                                        .italic()
                                        .foregroundColor(t.textColor.opacity(0.5))
                                    Text(plant.season)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .tracking(2)
                                        .foregroundColor(t.accent.opacity(0.7))
                                }

                                Spacer()

                                // Add indicator
                                ZStack {
                                    Circle()
                                        .fill(t.accent.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(t.accent)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(t.background)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(t.accent.opacity(0.18), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }

            // Cancel
            Button { dismiss() } label: {
                Text("Cancel")
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(text.opacity(0.4))
                    .padding(.vertical, 16)
            }
            .padding(.bottom, 16)
        }
    }
}
