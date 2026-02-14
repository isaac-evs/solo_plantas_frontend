//
//  PlantDNA.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 14/02/26.
//

import Foundation
import SwiftUI

struct PlantDNA: Codable, Identifiable {
    
    var id: UUID = UUID()
    
    /// Average RGB Color of the Plant
    let colorComponents: [Float]
    
    /// Physical height of the plant in meters
    let height: Float
    
    /// Ratio of Height/Width
    let shapeRatio: Float
    
    /// Time the plant was created
    let timestamp: Date
    
    /// Helper Methods
    var switfUIColor: Color {
        guard colorComponents.count >= 3 else { return .green }
        return Color(
            red: Double(colorComponents[0]),
            green: Double(colorComponents[1]),
            blue: Double(colorComponents[2])
        )
    }
}
