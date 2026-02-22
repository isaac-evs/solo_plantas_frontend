//
//  Nursery.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
//

import Foundation
import MapKit

// Map Pin
struct Nursery: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let description: String
    let coordinate: CLLocationCoordinate2D
}
