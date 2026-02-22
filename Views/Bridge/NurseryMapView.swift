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
    
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                //  Map
                Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.nurseries) { nursery in
                    MapAnnotation(coordinate: nursery.coordinate) {
                        Image(systemName: "leaf.circle.fill")
                            .resizable()
                            .foregroundColor(.green)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.white))
                            .shadow(radius: 3)
                            .onTapGesture {
                                viewModel.selectNursery(nursery)
                            }
                    }
                }
                .ignoresSafeArea()
                
                // Bottom Popup Card
                if let nursery = viewModel.selectedNursery {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(nursery.name)
                                .font(.headline)
                            Spacer()
                            Button(action: { viewModel.clearSelection() }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                        
                        Text(nursery.address)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(nursery.description)
                            .font(.caption)
                            .padding(.bottom, 5)
                        
                        // Button
                        PrimaryButton(title: "Get Directions", icon: "map.fill", backgroundColor: .blue) {
                            viewModel.openInAppleMaps(nursery: nursery)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
