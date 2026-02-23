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
                    "id": "primavera",
                    "name": "Primavera",
                    "scientificName": "Roseodendron donnell-smithii",
                    "description": "A magnificent canopy tree reaching up to 30 meters, exploding with clustered yellow flowers that scatter winged seeds into the wind.",
                    "ecologicalRole": "Provides crucial high-canopy shelter and early-season nectar for native insects.",
                    "careInstructions": [
                      "Plant in well-drained soil",
                      "Avoid continuous watering",
                      "Requires ample space for a 5-7m crown"
                    ],
                    "season": "Blooms January–March",
                    "illustrationName": "Card_Primavera",
                    "growthType": "tall",
                    "dominantColor": "yellow",
                    "lsystem": {
                        "axiom": "X",
                        "rules": {"X": "F-[[X]+X]+F[+FX]-O", "F": "FF"},
                        "branchAngle": 22.5,
                        "baseThickness": 0.035,
                        "lengthMultiplier": 0.95,
                        "leafScale": 0.2,
                        "flowerScale": 0.2,
                        "stemColor": "#4A3B2C",
                        "leafColor": "#EBE02E",
                        "flowerColor": "#EBE02E"
                      }
                  },
                  {
                    "id": "guachumil",
                    "name": "Guachumil",
                    "scientificName": "Leucaena macrophylla",
                    "description": "A highly resilient tree with a wide crown, featuring fragrant white puffball flowers and twisted pendant pods.",
                    "ecologicalRole": "Highly adaptable soil-stabilizer that resists prolonged droughts and urban conditions.",
                    "careInstructions": [
                      "Requires direct sunlight",
                      "Protect from frost",
                      "Adapts well to clay, sandy, or acidic soils"
                    ],
                    "season": "Blooms February–March",
                    "illustrationName": "Card_Guachumil",
                    "growthType": "wide",
                    "dominantColor": "white",
                    "lsystem": {
                        "axiom": "X",
                        "rules": {"X": "F[+X]F[-X]+X", "F": "FF"},
                        "branchAngle": 35.0,
                        "baseThickness": 0.010,
                        "lengthMultiplier": 0.92,
                        "leafScale": 0.022,
                        "flowerScale": 0.030,
                        "stemColor": "#5C4A3D",
                        "leafColor": "#3B7A2E",
                        "flowerColor": "#FFFFFF"
                      }
                  },
                  {
                    "id": "mezquite",
                    "name": "Mezquite",
                    "scientificName": "Prosopis laevigata",
                    "description": "A legendary, deeply rooted tree with cracked blackish bark, thorny branches, and fragrant cream-yellowish flowers.",
                    "ecologicalRole": "A keystone desert species whose wide ecological range allows it to shelter countless wildlife species.",
                    "careInstructions": [
                      "Prefers plains and lowlands",
                      "Requires deep soils for taproots",
                      "Extremely drought tolerant"
                    ],
                    "season": "Blooms Spring",
                    "illustrationName": "Card_Mezquite",
                    "growthType": "wide",
                    "dominantColor": "yellow",
                    "lsystem": {
                        "axiom": "X",
                        "rules": {"X": "F-[[X]+X]+F[+FX]-X", "F": "F"},
                        "branchAngle": 40.0,
                        "baseThickness": 0.014,
                        "lengthMultiplier": 0.90,
                        "leafScale": 0.022,
                        "flowerScale": 0.028,
                        "stemColor": "#3E362E",
                        "leafColor": "#556B2F",
                        "flowerColor": "#F5F5DC"
                      }
                  },
                  {
                    "id": "salvia",
                    "name": "Salvia",
                    "scientificName": "Salvia mexicana",
                    "description": "An ancient native resident featuring tall, straight vertical stalks that end in striking deep purple flower spikes.",
                    "ecologicalRole": "A crucial, high-value nectar source for migrating hummingbirds across Jalisco.",
                    "careInstructions": [
                      "Partial to full sun",
                      "Needs well-draining soil",
                      "Water when top inch of soil is dry"
                    ],
                    "season": "Blooms Late Summer–Fall",
                    "illustrationName": "Card_Salvia",
                    "growthType": "tall",
                    "dominantColor": "purple",
                   "lsystem": {
                       "axiom": "X",
                       "rules": {"X": "F-[[X]+X]+F[+FX]-X", "F": "F"},
                       "branchAngle": 15.0,
                       "baseThickness": 0.008,
                       "lengthMultiplier": 0.95,
                       "leafScale": 0.018,
                       "flowerScale": 0.025,
                       "stemColor": "#6B8E23",
                       "leafColor": "#4B5320",
                       "flowerColor": "#4B0082"
                     }
                  },
                  {
                    "id": "tronadora",
                    "name": "Tronadora",
                    "scientificName": "Tecoma stans",
                    "description": "A beautiful, vibrant shrub that explodes with bright yellow, trumpet-shaped flowers. Easily pruned to fit any garden.",
                    "ecologicalRole": "Provides a continuous source of nectar for native bees and local bird populations.",
                    "careInstructions": [
                      "Full sun exposure",
                      "Water regularly until established",
                      "Prune annually to maintain shape"
                    ],
                    "season": "Blooms Spring–Fall",
                    "illustrationName": "Card_Tronadora",
                    "growthType": "balanced",
                    "dominantColor": "yellow",
                     "lsystem": {
                       "axiom": "X",
                       "rules": {"X": "F-[[X]+X]+F[+FX]-X", "F": "FF"},
                       "branchAngle": 30.0,
                       "baseThickness": 0.010,
                       "lengthMultiplier": 0.92,
                       "leafScale": 0.022,
                       "flowerScale": 0.032,
                       "stemColor": "#8B7355",
                       "leafColor": "#32CD32",
                       "flowerColor": "#FFD700"
                     }
                  },
                  {
                    "id": "cempasuchil",
                    "name": "Cempasúchil",
                    "scientificName": "Tagetes erecta",
                    "description": "The iconic Mexican Marigold. A bushy, structural plant with brilliant orange blooms deeply tied to Mexican heritage.",
                    "ecologicalRole": "Releases natural compounds into the soil that protect neighboring plants from harmful nematodes.",
                    "careInstructions": [
                      "Full sun",
                      "Pinch off dead blooms to encourage more",
                      "Do not overwater"
                    ],
                    "season": "Blooms Autumn (Día de Muertos)",
                    "illustrationName": "Card_Cempasuchil",
                    "growthType": "balanced",
                    "dominantColor": "orange",
                   "lsystem": {
                      "axiom": "X",
                      "rules": {"X": "F[+X][-X]F[-X]+X", "F": "FF"},
                      "branchAngle": 45.0,
                      "baseThickness": 0.008,
                      "lengthMultiplier": 0.88,
                      "leafScale": 0.020,
                      "flowerScale": 0.035,
                      "stemColor": "#228B22",
                      "leafColor": "#006400",
                      "flowerColor": "#FFA500"
                    }
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
