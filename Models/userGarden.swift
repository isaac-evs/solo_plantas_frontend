//
//  userGarden.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import Foundation

struct UserGarden: Codable {
    var unlockedPlantIDs: Set<String>
    var lastUpdated: Date
}
