//
//  WatercolorCard.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI

struct WatercolorCard: View {
    let title: String
    let subtitle: String
    let illustrationName: String
    let action: () -> Void

    private let t: SeedPacketTheme

    init(title: String, subtitle: String, illustrationName: String, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.illustrationName = illustrationName
        self.action = action
        // Derive theme from plant id embedded in illustrationName (e.g. "Card_Primavera" → "primavera")
        let id = title.lowercased()
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "ú", with: "u")
        self.t = seedTheme(for: id)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(t.background)
                    .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 8)

                // Dot scatter background
                GeometryReader { g in
                    let xs: [CGFloat] = [20, 90, 170, 50, 130, 210, 30, 110]
                    let ys: [CGFloat] = [30, 60, 25, 110, 85, 50, 160, 140]
                    let ds: [CGFloat] = [6, 12, 8, 18, 10, 7, 14, 9]
                    ForEach(0..<8, id: \.self) { i in
                        Circle()
                            .fill(t.patternColor.opacity(0.10))
                            .frame(width: ds[i], height: ds[i])
                            .offset(x: xs[i], y: ys[i])
                    }
                }
                .clipped()

                VStack(alignment: .leading, spacing: 0) {
                    // Top label
                    HStack {
                        Text("NATIVE SPECIES")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(t.accent.opacity(0.6))
                        Spacer()
                        ZStack {
                            Circle()
                                .strokeBorder(t.accent.opacity(0.25), lineWidth: 1.5)
                                .frame(width: 32, height: 32)
                            Text("MX")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(t.accent.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 14)

                    Rectangle()
                        .fill(t.accent.opacity(0.12))
                        .frame(height: 1)
                        .padding(.horizontal, 20)

                    // Illustration
                    ZStack {
                        Ellipse()
                            .fill(t.patternColor.opacity(0.13))
                            .frame(width: 130, height: 130)
                        Image(illustrationName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 110)
                            .shadow(color: t.accent.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)

                    Rectangle()
                        .fill(t.accent.opacity(0.12))
                        .frame(height: 1)
                        .padding(.horizontal, 20)

                    // Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(t.textColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(subtitle)
                            .font(.system(size: 11, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(t.textColor.opacity(0.45))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 20)
                }
            }
            .frame(width: 240, height: 340)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
