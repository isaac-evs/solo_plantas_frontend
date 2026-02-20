//
//  PlantSpecies.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
//

struct PlantSpecies: Identifiable, Codable {
    let id: String
    let name: String
    let scientificName: String
    let description: String
    let ecologicalRole: String
    let careInstructions: [String]
    let season : String
    let IllustrationName: String
    let lSystemType: PlantType
    let isLocked: Bool
}
