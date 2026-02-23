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
        background: Color(hex: "#F5F0E8"),
        accent:     Color(hex: "#4A7C59"),
        textColor:  Color(hex: "#1A2E1A"),
        patternColor: Color(hex: "#7AAF8E")
    )
}

// --- Card ---

struct SeedPacketCard: View {
    public let plant: PlantSpecies
    public let theme: SeedPacketTheme
    public let screenSize: CGSize

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

            VStack(alignment: .leading, spacing: 0) {

                // Top band
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NATIVE SPECIES")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(theme.accent.opacity(0.6))
                        Text(plant.season.uppercased())
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(theme.textColor.opacity(0.4))
                    }
                    Spacer()
                    // Stamp
                    ZStack {
                        Circle()
                            .strokeBorder(theme.accent.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 48, height: 48)
                        Circle()
                            .strokeBorder(theme.accent.opacity(0.15), lineWidth: 1)
                            .frame(width: 42, height: 42)
                        Text("MX")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.accent.opacity(0.6))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)
                .padding(.bottom, 20)

                Rectangle()
                    .fill(theme.accent.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 28)

                // Illustration
                ZStack {
                    Ellipse()
                        .fill(theme.patternColor.opacity(0.15))
                        .frame(width: screenSize.width * 0.55, height: screenSize.width * 0.55)
                    Image(plant.illustrationName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: screenSize.height * 0.22)
                        .shadow(color: theme.accent.opacity(0.2), radius: 12, x: 0, y: 6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)

                Rectangle()
                    .fill(theme.accent.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 28)

                // Name
                VStack(alignment: .leading, spacing: 6) {
                    Text(plant.name)
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundColor(theme.textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(plant.scientificName)
                        .font(.system(size: 13, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(theme.textColor.opacity(0.5))
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Description
                Text(plant.ecologicalRole)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(theme.textColor.opacity(0.65))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 28)

                Spacer()

                // Bottom bar
                HStack(spacing: 10) {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 10, height: 10)
                    Text(plant.dominantColor.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(theme.textColor.opacity(0.4))
                    Spacer()
                    Text("JALISCO, MX")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(theme.textColor.opacity(0.3))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
        .frame(width: screenSize.width * 0.82, height: screenSize.height * 0.68)
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
