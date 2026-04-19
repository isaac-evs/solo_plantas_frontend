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
    @EnvironmentObject var cart: CartManager

    private var t: SeedPacketTheme { seedTheme(for: plant.id) }
    private let s: CGFloat = 1.35
    
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        ZStack {
            t.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FIELD NOTES")
                                .font(.system(size: 10 * s, weight: .bold))
                                .tracking(4)
                                .foregroundColor(t.accent.opacity(0.8))
                            
                            Text(plant.name)
                                .font(.system(size: 36 * s, weight: .bold))
                                .foregroundColor(t.textColor)
                                .accessibilityAddTraits(.isHeader)
                            
                            Text(plant.scientificName)
                                .font(.system(size: 15 * s, weight: .regular))
                                .italic()
                                .foregroundColor(t.textColor.opacity(0.5))
                            
                            if let price = plant.price {
                                let formatter = NumberFormatter()
                                formatter.numberStyle = .currency
                                formatter.currencyCode = "MXN"
                                if let str = formatter.string(from: NSNumber(value: price)) {
                                    Text(str)
                                        .font(.system(size: 18 * s, weight: .bold))
                                        .foregroundColor(t.textColor)
                                        .padding(.top, 4)
                                }
                            }
                        }
                        
                        Spacer(minLength: 20)
                        
                        let imgSize: CGFloat = isIpad ? 180 : 110
                        let ringSize: CGFloat = isIpad ? 200 : 124
                        
                        ZStack {
                            Circle()
                                .fill(t.patternColor.opacity(0.15))
                                .frame(width: ringSize, height: ringSize)
                            
                            Image(plant.illustrationName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: imgSize, height: imgSize)
                                .clipShape(Circle())
                        }
                        .shadow(color: t.accent.opacity(0.15), radius: 10, x: 0, y: 5)
                        .accessibilityLabel("\(plant.name) hand-painted illustration")
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 40)
                    .padding(.bottom, 30)

                    // Divider
                    Rectangle()
                        .fill(t.accent.opacity(0.15))
                        .frame(height: 1.5)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 35)

                    // Ecological role
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            Text("ECOLOGICAL ROLE")
                                .font(.system(size: 10 * s, weight: .bold))
                                .tracking(3)
                                .foregroundColor(t.accent.opacity(0.8))
                        } icon: {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 14))
                                .foregroundColor(t.accent)
                        }

                        Text(plant.ecologicalRole)
                            .font(.system(size: 17 * s))
                            .foregroundColor(t.textColor.opacity(0.85))
                            .lineSpacing(6)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                    .accessibilityElement(children: .combine)

                    // Care instructions
                    VStack(alignment: .leading, spacing: 20) {
                        Label {
                            Text("CARE INSTRUCTIONS")
                                .font(.system(size: 10 * s, weight: .bold))
                                .tracking(3)
                                .foregroundColor(t.accent.opacity(0.8))
                        } icon: {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 14))
                                .foregroundColor(t.accent)
                        }
                        .padding(.bottom, 10)

                        ForEach(Array(plant.careInstructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 18) {
                                // Step Indicator
                                ZStack {
                                    Circle()
                                        .fill(t.accent)
                                        .frame(width: 34, height: 34)
                                    Text("\(index + 1)")
                                        .font(.system(size: 14 * s, weight: .bold))
                                        .foregroundColor(t.background)
                                }
                                .accessibilityHidden(true)

                                Text(instruction)
                                    .font(.system(size: 17 * s))
                                    .foregroundColor(t.textColor)
                                    .lineSpacing(5)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .accessibilityLabel("Step \(index + 1): \(instruction)")
                            }
                            .padding(.bottom, 12)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 60)
                    
                    // Add to Cart Button Action
                    Button {
                        cart.addToCart(plant: plant)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bag.fill.badge.plus")
                                .font(.system(size: 20, weight: .bold))
                            Text("Add to Cart")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(t.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(t.textColor)
                        .cornerRadius(16)
                        .shadow(color: t.textColor.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 60)
                }
            }
        }
    }
}
