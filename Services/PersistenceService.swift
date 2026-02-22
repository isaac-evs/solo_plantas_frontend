//
//  PersistenceService.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
//

import Foundation

final class PersistenceService: Sendable {
    
    static let shared = PersistenceService()
    
    // Key
    private let storageKey = "virtual_garden_save_data"
    
    private init() {}
    
    // -- Save Data ---
    func saveGarden(plantIDs: Set<String>){
        let garden = UserGarden(unlockedPlantIDs: plantIDs, lastUpdated: Date())
        
        do {
            let data = try JSONEncoder().encode(garden)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("Persistence: Saved \(plantIDs.count) plants to device.")
        } catch {
            print("Persistence: Failed to encode garden. Error: \(error)")
        }
    }
    
    // -- Load Data --
    func loadGarden() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            print("Persistence: No previous save file found. Starting a new one.")
            return []
        }
        
        do {
            let garden = try JSONDecoder().decode(UserGarden.self, from: data)
            print("Persistence: Loaded \(garden.unlockedPlantIDs.count) plants.")
            return garden.unlockedPlantIDs
        } catch {
            print("Persitence: Failed to decode garden. Error: \(error)")
            return []
        }
    }
}
