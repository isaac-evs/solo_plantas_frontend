//
//  ARGardenView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 13/02/26.
//

import SwiftUI

struct ARGardenView: View{
    
    var plant: PlantDNA
    
    var body: some View{
        VStack {
            Text("AR Garden Coming Soon")
                .font(.title)
            Text("DNA: \(plant.id)")
                .font(.caption)
        }
    }
}
