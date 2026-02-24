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
    var localNurseries: [Nursery] = []
    
    private init() {
        loadCatalog()
        loadNurseries()
    }
    
    private func loadCatalog() {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json") else {
            print("Data: Could not find catalog.json in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.catalog = try JSONDecoder().decode([PlantSpecies].self, from: data)
            print("Data: Loaded \(catalog.count) plants from catalog.json")
        } catch {
            print("Data: Failed to decode catalog.json: \(error)")
        }
    }
    
    private func loadNurseries() {
        guard let url = Bundle.main.url(forResource: "nurseries", withExtension: "json") else {
            print("Data: Could not find nurseries.json in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            // Decode into DTO
            let dtos = try JSONDecoder().decode([NurseryDTO].self, from: data)
            
            // Map the JSON data
            self.localNurseries = dtos.map { dto in
                Nursery(
                    name: dto.name,
                    address: dto.address,
                    description: dto.description,
                    coordinate: CLLocationCoordinate2D(latitude: dto.latitude, longitude: dto.longitude)
                )
            }
            print("Data: Loaded \(localNurseries.count) nurseries from nurseries.json")
        } catch {
            print("Data: Failed to decode nurseries.json: \(error)")
        }
    }
    
    func getPlant(by id: String) -> PlantSpecies? {
        return catalog.first { $0.id == id }
    }
}


fileprivate struct NurseryDTO: Decodable {
    let name: String
    let address: String
    let description: String
    let latitude: Double
    let longitude: Double
}
