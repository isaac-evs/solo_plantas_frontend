//
//  PlantSpecies.swift
//  VirtualGarden
//

import Foundation
import CoreGraphics

enum GrowthType: String, Codable, Equatable, Sendable {
    case tall
    case wide
    case balanced
}

enum PlantColorCategory: String, Codable, Sendable {
    case blue, yellow, purple, green, white, orange
}

enum SeasonCategory: String, Codable, Sendable {
    case spring, summer, fall, winter
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
    let season: String
    let seasonCategory: SeasonCategory
    let riddle: String
    let illustrationName: String
    let growthType: GrowthType
    let dominantColor: PlantColorCategory
    let growthMilestones: [Int]
    let lsystem: LSystemDNA
    let price: Double?
}

extension String {
    func toRGB() -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        var hex = self.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        return (
            CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            CGFloat((rgb & 0x00FF00) >> 8)  / 255.0,
            CGFloat(rgb & 0x0000FF)          / 255.0
        )
    }
}
