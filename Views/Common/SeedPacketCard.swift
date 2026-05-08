//
//  SeedPacketCard.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 23/02/26.
//

import SwiftUI

// -- Theme ---

public struct SeedPacketTheme: Sendable {
    public let background: Color
    public let accent: Color
    public let textColor: Color
    public let patternColor: Color
}

@MainActor
public let seedPacketThemes: [String: SeedPacketTheme] = [
    "primavera":   SeedPacketTheme(background: Color(hex: "#F7F0DC"), accent: Color(hex: "#D4A017"),  textColor: Color(hex: "#2C1810"), patternColor: Color(hex: "#E8C84A")),
    "guachumil":   SeedPacketTheme(background: Color(hex: "#EDF4EC"), accent: Color(hex: "#3B7A2E"),  textColor: Color(hex: "#1A2E1A"), patternColor: Color(hex: "#6AAF5E")),
    "mezquite":    SeedPacketTheme(background: Color(hex: "#F5EDE0"), accent: Color(hex: "#8B5E3C"),  textColor: Color(hex: "#2E1A0E"), patternColor: Color(hex: "#C4956A")),
    "salvia":      SeedPacketTheme(background: Color(hex: "#F0EDF7"), accent: Color(hex: "#4B0082"),  textColor: Color(hex: "#1A1028"), patternColor: Color(hex: "#9B6BBE")),
    "tronadora":   SeedPacketTheme(background: Color(hex: "#FDFBE8"), accent: Color(hex: "#C8A800"),  textColor: Color(hex: "#2A2000"), patternColor: Color(hex: "#E8D44A")),
    "cempasuchil": SeedPacketTheme(background: Color(hex: "#FFF1E6"), accent: Color(hex: "#E05C00"),  textColor: Color(hex: "#2E1200"), patternColor: Color(hex: "#F4924A")),
]

@MainActor
func seedTheme(for id: String) -> SeedPacketTheme {
    seedPacketThemes[id] ?? SeedPacketTheme(
        background:   Color(hex: "#F5F0E8"),
        accent:       Color(hex: "#4A7C59"),
        textColor:    Color(hex: "#1A2E1A"),
        patternColor: Color(hex: "#7AAF8E")
    )
}

// --- Card ---

struct SeedPacketCard: View {
    public let plant: PlantSpecies
    public let theme: SeedPacketTheme
    public let screenSize: CGSize

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var s: CGFloat { isIpad ? 2.0 : 1.25 }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(plant: PlantSpecies, theme: SeedPacketTheme, screenSize: CGSize) {
        self.plant      = plant
        self.theme      = theme
        self.screenSize = screenSize
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.background)
                .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 12)

            GeometryReader { _ in
                let xs: [CGFloat] = [30,110,200,60,150,250,40,130,220,80,170,290,20,100,190,70,160,240]
                let ys: [CGFloat] = [40,80,30,140,100,60,200,160,120,300,250,90,350,310,270,400,370,330]
                let ds: [CGFloat] = [8,14,6,20,10,16,7,12,18,9,15,11,5,22,8,13,17,6]
                ForEach(0..<18, id: \.self) { i in
                    Circle()
                        .fill(theme.patternColor.opacity(0.12))
                        .frame(width: ds[i], height: ds[i])
                        .offset(x: xs[i], y: ys[i])
                }
            }
            .clipped()
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {

                // Season header
                Text(plant.season)
                    .font(.system(size: 11 * s, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(theme.accent.opacity(0.75))
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 12)
                    .accessibilityLabel("Blooming season: \(plant.season)")

                Rectangle()
                    .fill(theme.accent.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                    .accessibilityHidden(true)

                let circleSize = isIpad ? 240.0 : screenSize.width * 0.48
                
                ZStack {
                    Circle()
                        .fill(theme.patternColor.opacity(0.25))
                        .frame(width: circleSize + 16, height: circleSize + 16)
                    
                    Image(plant.illustrationName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: circleSize, height: circleSize)
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .shadow(color: theme.accent.opacity(0.25), radius: 12, x: 0, y: 6)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(plant.name)  illustration")

                Rectangle()
                    .fill(theme.accent.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                    .accessibilityHidden(true)

                // Plant name
                VStack(alignment: .leading, spacing: 6) {
                    Text(plant.name)
                        .font(.system(size: 36 * s, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .accessibilityAddTraits(.isHeader)

                    Text(plant.scientificName)
                        .font(.system(size: 13 * s, weight: .regular))
                        .italic()
                        .foregroundColor(theme.textColor.opacity(0.5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .accessibilityLabel("Scientific name: \(plant.scientificName)")
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 10)

                // Ecological role
                Text(plant.ecologicalRole)
                    .font(.system(size: 13 * s, weight: .regular))
                    .foregroundColor(theme.textColor.opacity(0.65))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                    .accessibilityLabel("Ecological role: \(plant.ecologicalRole)")

                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plant.name), \(plant.scientificName). \(plant.season). \(plant.ecologicalRole)")
        .accessibilityHint("Swipe left or right to browse plants. Double-tap Plant this seed to select.")
    }
}

// --- Color ---

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
