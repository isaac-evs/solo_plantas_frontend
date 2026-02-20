//
//  PlantDNA.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 14/02/26.
//

import Foundation
import SwiftUI

struct PlantDNA: Identifiable, Codable {
    let id: UUID
    let speciesID: String 
    let datePlanted: Date
    let colorComponents: [Float]
    let height: Float
    let shapeRatio: Float
}
