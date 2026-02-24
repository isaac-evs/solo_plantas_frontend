//
//  PlantSpecies.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
//

import Foundation
import CoreGraphics

enum GrowthType: String, Codable, Equatable, Sendable {
    case tall
    case wide
    case balanced
}

enum PlantColorCategory: String, Codable, Sendable {
    case blue
    case yellow
    case purple
    case green
    case white
    case orange
}

struct LSystemDNA: Codable, Equatable, Sendable {
    let axiom: String
    let rules: [String: String]
    let branchAngle: Float
    let baseThickness: Float
    let lengthMultiplier: Float
    let leafScale: Float
    let flowerScale: Float
    let stemColor: String
    let leafColor: String
    let flowerColor: String
}

struct PlantSpecies: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let name: String
    let scientificName: String
    let description: String
    let ecologicalRole: String
    let careInstructions: [String]
    let season : String
    let illustrationName: String
    let growthType: GrowthType
    let dominantColor: PlantColorCategory
    let growthMilestones: [Int]
    let lsystem: LSystemDNA
}

extension String {
    func toRGB() -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        var hexSanitized = self.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        return (r, g, b)
    }
}
