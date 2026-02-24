//
//  userGarden.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import Foundation

struct UserGarden: Codable {
    var plantedDates: [String: Date]
    var lastUpdated: Date
}
