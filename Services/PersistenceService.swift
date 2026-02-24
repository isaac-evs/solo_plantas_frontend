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
    func saveGarden(plantedDates: [String: Date]){
        let garden = UserGarden(plantedDates: plantedDates, lastUpdated: Date())
        
        do {
            let data = try JSONEncoder().encode(garden)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("Persistence: Saved \(plantedDates.count) plants to device.")
        } catch {
            print("Persistence: Failed to encode garden. Error: \(error)")
        }
    }
    
    // -- Load Data --
    func loadGarden() -> [String: Date] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            print("Persistence: No previous save file found. Starting a new one.")
            return [:]
        }
        
        do {
            let garden = try JSONDecoder().decode(UserGarden.self, from: data)
            print("Persistence: Loaded \(garden.plantedDates.count) plants.")
            return garden.plantedDates
        } catch {
            print("Persistence: Failed to decode garden. Error: \(error)")
            return [:]
        }
    }
}
