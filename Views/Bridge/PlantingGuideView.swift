//
//  PlantingGuideView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//


import SwiftUI

struct PlantingGuideView: View {
    @Environment(\.dismiss) var dismiss
    let plant: PlantSpecies

    private let t: SeedPacketTheme

    init(plant: PlantSpecies) {
        self.plant = plant
        self.t = seedTheme(for: plant.id)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {

                    // Header
                    VStack(spacing: 8) {
                        Text("HOW TO PLANT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(4)
                            .foregroundColor(t.accent.opacity(0.7))

                        Text(plant.name)
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundColor(t.textColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(t.background)

                    // Steps
                    VStack(spacing: 0) {
                        ForEach(Array(plant.careInstructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 16) {

                                VStack(spacing: 0) {
                                    ZStack {
                                        Circle()
                                            .fill(t.accent)
                                            .frame(width: 32, height: 32)
                                        Text("\(index + 1)")
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(t.background)
                                    }
                                    if index < plant.careInstructions.count - 1 {
                                        Rectangle()
                                            .fill(t.accent.opacity(0.2))
                                            .frame(width: 1.5)
                                            .frame(maxHeight: .infinity)
                                            .padding(.vertical, 4)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Step \(index + 1)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .tracking(3)
                                        .foregroundColor(t.accent.opacity(0.6))
                                    Text(instruction)
                                        .font(.system(size: 16, design: .serif))
                                        .foregroundColor(t.textColor)
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.bottom, 28)

                                Spacer()
                            }
                            .padding(.horizontal, 28)
                        }
                    }
                    .padding(.top, 28)

                    // Footer
                    VStack(spacing: 10) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 18))
                            .foregroundColor(t.accent.opacity(0.5))

                        Text("Come back when you plant yours — your virtual \(plant.name) will grow alongside the real one.")
                            .font(.system(size: 13, design: .serif))
                            .italic()
                            .foregroundColor(t.textColor.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                    .background(t.background.opacity(0.5))
                    .padding(.top, 8)
                }
            }
            .background(Color(hex: "#F5F0E8").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                }
            }
        }
    }
}
