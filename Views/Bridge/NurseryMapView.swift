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
    
    private let textScale: CGFloat = 1.35

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.nurseries) { nursery in
                    MapAnnotation(coordinate: nursery.coordinate) {
                        Button {
                            viewModel.selectNursery(nursery)
                        } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 32, height: 32)
                                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                                    Image(systemName: "leaf.circle.fill")
                                        .resizable()
                                        .foregroundColor(Color(hex: "#3B7A2E"))
                                        .frame(width: 36, height: 36)
                                }
                                Triangle()
                                    .fill(Color.white)
                                    .frame(width: 12, height: 8)
                                    .shadow(color: .black.opacity(0.1), radius: 1)
                            }
                        }
                        .accessibilityLabel("Nursery: \(nursery.name)")
                        .accessibilityHint("Shows nursery details and directions")
                    }
                }
                .ignoresSafeArea()

                if let nursery = viewModel.selectedNursery {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(nursery.name)
                                    .font(.system(size: 22 * textScale, weight: .bold, design: .serif))
                                    .foregroundColor(Color(hex: "#2E1A0E"))
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text(nursery.address)
                                    .font(.system(size: 14 * textScale, design: .serif))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                withAnimation { viewModel.clearSelection() }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.gray)
                                    .padding(12)
                                    .background(Circle().fill(Color.gray.opacity(0.15)))
                            }
                            .accessibilityLabel("Close details")
                        }

                        Text(nursery.description)
                            .font(.system(size: 14 * textScale, design: .serif))
                            .foregroundColor(Color(hex: "#2E1A0E").opacity(0.7))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            viewModel.openInAppleMaps(nursery: nursery)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Get Directions")
                                    .font(.system(size: 17 * textScale, weight: .bold, design: .serif))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Color(hex: "#3B7A2E"))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color(hex: "#3B7A2E").opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Local Nurseries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 17 * textScale, weight: .bold, design: .serif))
                }
            }
        }
    }
}

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
