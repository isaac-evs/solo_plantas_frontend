//
//  PlantSpecies.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
//

import Foundation

enum GrowthType: String, Codable, Equatable {
    case tall
    case wide
    case balanced
}

struct PlantSpecies: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let scientificName: String
    let description: String
    let ecologicalRole: String
    let careInstructions: [String]
    let season : String
    let illustrationName: String
    let growthType: GrowthType
}
