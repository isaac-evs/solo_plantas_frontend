//
//  PlantDetailView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
//

import SwiftUI

struct PlantDetailView: View {
    let plant: PlantSpecies
    @Environment(\.dismiss) var dismiss

    private var t: SeedPacketTheme { seedTheme(for: plant.id) }

    var body: some View {
        ZStack {
            t.background.ignoresSafeArea()

            // Faint initial letter
            Text(String(plant.name.prefix(1)))
                .font(.system(size: 260, weight: .black, design: .serif))
                .foregroundColor(t.patternColor.opacity(0.08))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 40, y: 40)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("FIELD NOTES")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(4)
                                .foregroundColor(t.accent.opacity(0.7))
                            Text(plant.name)
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .foregroundColor(t.textColor)
                            Text(plant.scientificName)
                                .font(.system(size: 13, weight: .regular, design: .serif))
                                .italic()
                                .foregroundColor(t.textColor.opacity(0.45))
                        }
                        Spacer()
                        Image(plant.illustrationName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .shadow(color: t.accent.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                    .padding(.bottom, 22)

                    // Divider
                    Rectangle()
                        .fill(t.accent.opacity(0.12))
                        .frame(height: 1)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 24)

                    // Ecological role
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("ECOLOGICAL ROLE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .tracking(3)
                                .foregroundColor(t.accent.opacity(0.7))
                        } icon: {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 10))
                                .foregroundColor(t.accent)
                        }

                        Text(plant.ecologicalRole)
                            .font(.system(size: 15, design: .serif))
                            .foregroundColor(t.textColor.opacity(0.75))
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)

                    // Care instructions
                    VStack(alignment: .leading, spacing: 6) {
                        Label {
                            Text("CARE INSTRUCTIONS")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .tracking(3)
                                .foregroundColor(t.accent.opacity(0.7))
                        } icon: {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 10))
                                .foregroundColor(t.accent)
                        }
                        .padding(.bottom, 6)

                        ForEach(Array(plant.careInstructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 14) {
                                // Connected step line
                                VStack(spacing: 0) {
                                    ZStack {
                                        Circle()
                                            .fill(t.accent)
                                            .frame(width: 26, height: 26)
                                        Text("\(index + 1)")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(t.background)
                                    }
                                    if index < plant.careInstructions.count - 1 {
                                        Rectangle()
                                            .fill(t.accent.opacity(0.2))
                                            .frame(width: 1.5)
                                            .frame(maxHeight: .infinity)
                                            .padding(.vertical, 3)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(instruction)
                                        .font(.system(size: 15, design: .serif))
                                        .foregroundColor(t.textColor)
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.bottom, 18)

                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 20)

                    // Season + metadata strip
                    HStack(spacing: 0) {
                        metaChip(icon: "sun.max.fill",   label: plant.season)
                        Divider().frame(height: 32).padding(.horizontal, 12)
                        metaChip(icon: "mappin.fill",    label: "Jalisco, MX")
                        Divider().frame(height: 32).padding(.horizontal, 12)
                        metaChip(icon: "paintpalette.fill", label: plant.dominantColor.rawValue.capitalized)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(t.patternColor.opacity(0.10))
                    )
                    .padding(.horizontal, 28)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func metaChip(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(t.accent)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .serif))
                .foregroundColor(t.textColor.opacity(0.65))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
