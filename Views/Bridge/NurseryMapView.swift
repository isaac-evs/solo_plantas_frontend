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
                Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.nurseries) { nursery in
                    MapAnnotation(coordinate: nursery.coordinate) {
                        Button { viewModel.selectNursery(nursery) } label: {
                            VStack(spacing: 3) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 36, height: 36)
                                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                    Image(systemName: "leaf.circle.fill")
                                        .resizable()
                                        .foregroundColor(Color(hex: "#3B7A2E"))
                                        .frame(width: 26, height: 26)
                                }
                                // Pointer
                                Triangle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 5)
                                    .shadow(color: .black.opacity(0.1), radius: 1)
                            }
                        }
                    }
                }
                .ignoresSafeArea()

                if let nursery = viewModel.selectedNursery {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(nursery.name)
                                    .font(.system(size: 17, weight: .bold, design: .serif))
                                    .foregroundColor(Color(hex: "#2E1A0E"))
                                Text(nursery.address)
                                    .font(.system(size: 13, design: .serif))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button { viewModel.clearSelection() } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .padding(8)
                                    .background(Circle().fill(Color.gray.opacity(0.12)))
                            }
                        }

                        Text(nursery.description)
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(Color(hex: "#2E1A0E").opacity(0.65))
                            .lineSpacing(2)

                        Button {
                            viewModel.openInAppleMaps(nursery: nursery)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Get Directions")
                                    .font(.system(size: 15, weight: .semibold, design: .serif))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(hex: "#3B7A2E"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: -4)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Local Nurseries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedNursery?.id)
        }
    }
}

// Map pin
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
