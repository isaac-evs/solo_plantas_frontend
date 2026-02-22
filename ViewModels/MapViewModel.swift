//
//  MapViewModel.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI
import MapKit

@MainActor
class MapViewModel: ObservableObject {
    
    // Data
    @Published var nurseries: [Nursery] = []
    
    // State
    @Published var selectedNursery: Nursery?
    
    // Center map on Guadalajara
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20.6795, longitude: -103.3915),
        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )
    
    init() {
        loadNurseries()
    }
    
    private func loadNurseries() {
        self.nurseries = DataService.shared.localNurseries
    }
    
    func selectNursery(_ nursery: Nursery) {
        withAnimation {
            selectedNursery = nursery
        }
    }
    
    func clearSelection() {
        withAnimation {
            selectedNursery = nil
        }
    }
    
    // Apple Maps link
    func openInAppleMaps(nursery: Nursery) {
        let placemark = MKPlacemark(coordinate: nursery.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = nursery.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
