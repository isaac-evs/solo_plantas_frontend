//
//  WatercolorCard.swift
//  VirtualGarden
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

    private var cardW: CGFloat { screenSize.width * 0.82 }
    private var cardH: CGFloat { screenSize.height * 0.58 }

    var body: some View {
        VStack(spacing: 0) {

            // ── Name block — above the card ───────────────────
            VStack(alignment: .leading, spacing: isIpad ? 5 : 3) {
                Text(status.plant.name)
                    .font(.system(size: 38 * s, weight: .bold, design: .serif))
                    .foregroundColor(t.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .accessibilityAddTraits(.isHeader)

                Text(status.plant.scientificName)
                    .font(.system(size: 21 * s, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(t.textColor.opacity(0.45))
                    .lineLimit(1)
                    .accessibilityLabel("Scientific name: \(status.plant.scientificName)")
            }
            .frame(width: cardW, alignment: .leading)
            .padding(.bottom, isIpad ? 14 : 10)

            // ── Card ──────────────────────────────────────────
            ZStack(alignment: .topLeading) {

                // Base
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(t.background)
                    .shadow(color: .black.opacity(0.13), radius: 22, x: 0, y: 8)
                    .shadow(color: .black.opacity(0.05), radius: 5,  x: 0, y: 2)

                // Illustration fills the card
                Image(status.plant.illustrationName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardW, height: cardH)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityLabel("\(status.plant.name) illustration")

                // Top gradient for day pill legibility
                LinearGradient(
                    colors: [Color.black.opacity(0.22), Color.clear],
                    startPoint: .top,
                    endPoint: .init(x: 0.5, y: 0.28)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                // Bottom gradient for AR button legibility
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.18)],
                    startPoint: .init(x: 0.5, y: 0.72),
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                // Day pill — top left, white bg black text
                Text("DAY \(status.daysElapsed)")
                    .font(.system(size: 11 * s, weight: .bold, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(.black)
                    .padding(.horizontal, isIpad ? 14 : 11)
                    .padding(.vertical, isIpad ? 7 : 5)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 2)
                    )
                    .padding(isIpad ? 18 : 14)
                    .accessibilityLabel("Day \(status.daysElapsed)")

                // AR button — bottom right, white circle black icon
                Button(action: onARTap) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: isIpad ? 52 : 42, height: isIpad ? 52 : 42)
                            .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 3)
                        Image(systemName: "arkit")
                            .font(.system(size: isIpad ? 20 : 16, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                .frame(width: cardW, height: cardH, alignment: .bottomTrailing)
                .padding(isIpad ? 18 : 14)
                .accessibilityLabel("View \(status.plant.name) in augmented reality")
                .accessibilityHint("Opens AR camera to place your plant in your space")
            }
            .frame(width: cardW, height: cardH)
        }
        .accessibilityElement(children: .contain)
    }
}
