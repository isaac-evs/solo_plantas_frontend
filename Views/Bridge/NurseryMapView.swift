//
//  NurseryMapView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI
import MapKit

struct NurseryMapView: View {
    @Environment(\.dismiss) var dismiss
    
    // Center map in Guadalajara Jalisco
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20.6795, longitude: -103.3915),
        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )
    
    @State private var selectedNursery: Nursery?
    
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $region, annotationItems: DataService.shared.localNurseries){ nursery in
                    MapAnnotation(coordinate: nursery.coordinate) {
                        Image(systemName: "leaf.circle.fill")
                            .resizable()
                            .foregroundColor(.green)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.white))
                            .onTapGesture {
                                withAnimation { selectedNursery = nursery }
                            }
                    }
                }
                .ignoresSafeArea()
                
                // Popup Card
                if let nursery = selectedNursery {
                    VStack(alignment: .leading, spacing: 10){
                        HStack{
                            Text(nursery.name)
                                .font(.headline)
                            Spacer()
                            Button(action: { selectedNursery = nil }){
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                        
                        Text(nursery.address)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(nursery.description)
                            .font(.caption)
                            .padding(.bottom, 5)
                        
                        Button(action: {
                            openInAppleMaps(nursery: nursery)
                        }) {
                            Text("Get Directions")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .padding()
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Local Nurseries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    func openInAppleMaps(nursery: Nursery){
        let placemark = MKPlacemark(coordinate: nursery.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = nursery.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
