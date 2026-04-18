//
//  WatercolorCard.swift
//  VirtualGarden
//
// Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI

struct WatercolorCard: View {
    let status: PlantGrowthStatus
    let screenSize: CGSize
    let onARTap: () -> Void

    private var t: SeedPacketTheme { seedTheme(for: status.plant.id) }
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    
    private var s: CGFloat { isIpad ? 1.4 : 1.0 }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var stageIcon: String {
        let days = status.daysElapsed
        let m = status.plant.growthMilestones
        
        let m0 = m.count > 0 ? m[0] : 5
        let m1 = m.count > 1 ? m[1] : 20
        let m2 = m.count > 2 ? m[2] : 40
        let m3 = m.count > 3 ? m[3] : 70

        if days < m0 { return "circle.dotted" }
        if days < m1 { return "leaf" }
        if days < m2 { return "leaf.fill" }
        if days < m3 { return "tree" }
        return "tree.fill"
    }

    var body: some View {
        VStack(spacing: 0) {

            // ──- Name block —--
            HStack(alignment: .bottom) {
                // Left: Names
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.plant.name)
                        .font(.system(size: isIpad ? 74 : 32, weight: .bold))
                        .foregroundColor(t.textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .accessibilityAddTraits(.isHeader)

                    Text(status.plant.scientificName)
                        .font(.system(size: isIpad ? 34 : 16, weight: .regular))
                        .italic()
                        .foregroundColor(t.textColor.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .accessibilityLabel("Scientific name: \(status.plant.scientificName)")
                }
                
                Spacer(minLength: 12)
                
                // Right: Stage Icon
                Image(systemName: stageIcon)
                    .font(.system(size: isIpad ? 74 : 36, weight: .light))
                    .foregroundColor(.black)
                    .padding(.trailing, isIpad ? 16 : 8)
                    .accessibilityHidden(true)
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, isIpad ? 24 : 16)

            // --- Card ---
            ZStack(alignment: .topLeading) {

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(t.background)
                    .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 12)

                Image(status.plant.illustrationName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: isIpad ? .infinity : screenSize.width * 0.82)
                    .frame(height: isIpad ? screenSize.height * 0.62 : screenSize.height * 0.52)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .accessibilityLabel("\(status.plant.name) illustration")

                LinearGradient(
                    colors: [Color.black.opacity(0.25), Color.clear],
                    startPoint: .top,
                    endPoint: .init(x: 0.5, y: 0.25)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.20)],
                    startPoint: .init(x: 0.5, y: 0.70),
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                // Day pill — top left
                Text("DAY \(status.daysElapsed)")
                    .font(.system(size: 12 * s, weight: .bold))
                    .tracking(3)
                    .foregroundColor(.black)
                    .padding(.horizontal, isIpad ? 16 : 14)
                    .padding(.vertical, isIpad ? 8 : 6)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                    )
                    .padding(isIpad ? 24 : 18)
                    .accessibilityLabel("Day \(status.daysElapsed)")

                // AR button — bottom right
                Button(action: onARTap) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: isIpad ? 64 : 54, height: isIpad ? 64 : 54)
                            .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 4)
                        Image(systemName: "arkit")
                            .font(.system(size: isIpad ? 22 : 18, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(isIpad ? 24 : 18)
                .accessibilityLabel("View \(status.plant.name) in augmented reality")
                .accessibilityHint("Opens AR camera to place your plant in your space")
            }
            .frame(maxWidth: isIpad ? .infinity : screenSize.width * 0.82)
            .frame(height: isIpad ? screenSize.height * 0.62 : screenSize.height * 0.52)
        }
        .accessibilityElement(children: .contain)
    }
}
