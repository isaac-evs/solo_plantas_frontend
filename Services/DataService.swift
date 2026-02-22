//
//  DataService.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
//

import Foundation
import MapKit

@MainActor
class DataService {
    
    static let shared = DataService()
    
    var catalog: [PlantSpecies] = []
    
    let localNurseries: [Nursery] = [
        Nursery(name: "Vivero Los Colomos",
                address: "Bosque Los Colomos, Guadalajara",
                description: "Carries Damiana, Salvia, and 12 other natives.",
                coordinate: CLLocationCoordinate2D(latitude: 20.7075, longitude: -103.3948)),
        Nursery(name: "Nativas de Jalisco",
                address: "Zapopan Centro",
                description: "Specializes in drought-tolerant native species.",
                coordinate: CLLocationCoordinate2D(latitude: 20.7196, longitude: -103.3892)),
        Nursery(name: "Jardín Botánico Vivero",
                address: "Tlaquepaque",
                description: "Carries Agave and native pollinator plants.",
                coordinate: CLLocationCoordinate2D(latitude: 20.6397, longitude: -103.3130))
    ]
    
    private init() {
        loadCatalog()
    }
    
    private func loadCatalog() {
        
        let rawJSON = """
                [
                  {
                    "id": "damiana",
                    "name": "Damiana",
                    "scientificName": "Turnera diffusa",
                    "description": "A small, aromatic shrub with vibrant yellow flowers. Native to Jalisco's scrublands.",
                    "ecologicalRole": "Feeds 8 native bee species found only in Jalisco.",
                    "careInstructions": [
                      "Plant in full sun",
                      "Water twice weekly for first month",
                      "Reduce to once weekly after established"
                    ],
                    "season": "Blooms April–June",
                    "illustrationName": "Card_Damiana",
                    "growthType": "balanced",
                    "dominantColor": "yellow"
                  },
                  {
                    "id": "salvia",
                    "name": "Salvia",
                    "scientificName": "Salvia mexicana",
                    "description": "A striking plant with deep blue to purple flowers. An ancient resident of these lands.",
                    "ecologicalRole": "A crucial nectar source for migrating hummingbirds.",
                    "careInstructions": [
                      "Partial to full sun",
                      "Needs well-draining soil",
                      "Water when top inch of soil is dry"
                    ],
                    "season": "Blooms Late Summer–Fall",
                    "illustrationName": "Card_Salvia",
                    "growthType": "tall",
                    "dominantColor": "purple"
                  },
                  {
                    "id": "agave",
                    "name": "Agave",
                    "scientificName": "Agave tequilana",
                    "description": "The iconic blue agave. Patient, resilient, and deeply tied to Jalisco's heritage.",
                    "ecologicalRole": "Provides shelter for desert birds and nectar for nocturnal bats.",
                    "careInstructions": [
                      "Maximum sun exposure",
                      "Requires sandy, rocky soil",
                      "Water very rarely"
                    ],
                    "season": "Blooms once after 5-10 years",
                    "illustrationName": "Card_Agave",
                    "growthType": "wide",
                    "dominantColor": "blue"
                  },
                  {
                    "id": "primavera",
                    "name": "Primavera",
                    "scientificName": "Roseodendron donnell-smithii",
                    "description": "A majestic tree that explodes with golden-yellow trumpet flowers, signaling the coming of spring.",
                    "ecologicalRole": "Provides canopy shelter and early-season nectar for native insects.",
                    "careInstructions": [
                      "Needs ample space to grow",
                      "Full sun",
                      "Drought tolerant once established"
                    ],
                    "season": "Blooms March-April",
                    "illustrationName": "Card_Primavera",
                    "growthType": "tall",
                    "dominantColor": "yellow"
                  }
                ]
                """
        
                let data = Data(rawJSON.utf8)
                let decoder = JSONDecoder()
        
        do {
            self.catalog = try decoder.decode([PlantSpecies].self, from: data)
            print("Data : Loaded \(catalog.count) plants from catalog") // DEBUG
        } catch {
            print("Data : Failed to decode Catalog.json: \(error)")
        }
    }
    
    func getPlant(by id: String) -> PlantSpecies? {
        return catalog.first { $0.id == id }
    }
}
