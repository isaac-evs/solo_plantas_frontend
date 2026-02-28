//
//  ScanView.swift
//  VirtualGarden
//
// Created by Isaac Vazquez Sandoval on 14/02/26.
//

import SwiftUI
import AVFoundation

struct ScanView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ScanViewModel()

    @Environment(\.accessibilityReduceMotion)       private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        ZStack {
            // Camera Layer
            CameraPreview(session: viewModel.cameraService.session)
                .ignoresSafeArea()
                .onAppear  { viewModel.startCamera() }
                .onDisappear { viewModel.stopCamera() }
                .accessibilityLabel("Camera viewfinder")

            // Reticle
            ZStack {
                Circle()
                    .fill(viewModel.liveColor == .clear ? Color.white.opacity(0.4) : viewModel.liveColor)
                    .frame(width: isIpad ? 80 : 54, height: isIpad ? 80 : 54)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
                    .shadow(color: .black.opacity(0.4), radius: 6)
                    .scaleEffect(viewModel.isScanning ? 1.4 : 1.0)
                    .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.isScanning)
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea()

            // UI
            VStack {
                
                VStack(spacing: isIpad ? 10 : 6) {
                    Text(viewModel.isScanning ? "Scanning Environment" : "Center a leaf or flower")
                        .font(.system(size: isIpad ? 34 : 26, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(viewModel.isScanning ? "Hold still…" : "Align it inside the circle")
                        .font(.system(size: isIpad ? 24 : 18, weight: .medium, design: .serif))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, isIpad ? 32 : 24)
                .padding(.vertical, isIpad ? 20 : 16)
                .background(
                    reduceTransparency
                        ? AnyView(RoundedRectangle(cornerRadius: isIpad ? 24 : 18, style: .continuous).fill(Color.white.opacity(0.85)))
                        : AnyView(
                            RoundedRectangle(cornerRadius: isIpad ? 24 : 18, style: .continuous)
                                .fill(Color.black.opacity(0.45))
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: isIpad ? 24 : 18, style: .continuous))
                        )
                )
                .padding(.top, isIpad ? 100 : 80)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    viewModel.isScanning
                        ? "Scanning Environment. Hold still."
                        : "Center a leaf or flower. Align it inside the circle."
                )

                Spacer()

                // Scan Button
                Button {
                    let ownedIDs = Set(appState.plantedDates.keys)
                    viewModel.performScan(unlockedIDs: ownedIDs)
                } label: {
                    HStack(spacing: 12) {
                        if viewModel.isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(isIpad ? 1.2 : 1.0)
                                .accessibilityHidden(true)
                        } else {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: isIpad ? 24 : 20, weight: .bold))
                                .accessibilityHidden(true)
                        }
                        Text(viewModel.isScanning ? "Scanning…" : "Identify Plant")
                            .font(.system(size: isIpad ? 24 : 20, weight: .bold, design: .serif))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: isIpad ? 450 : .infinity)
                    .frame(height: isIpad ? 80 : 66)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: isIpad ? 20 : 16, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .disabled(viewModel.isScanning)
                .opacity(viewModel.isScanning ? 0.8 : 1.0)
                .padding(.horizontal, isIpad ? 60 : 32)

                .padding(.bottom, isIpad ? 180 : 150)
            }
        }
        .sheet(isPresented: $viewModel.scanComplete, onDismiss: {
            viewModel.isScanning = false
        }) {
            MatchPlantView(matchedPlants: viewModel.matchedPlants)
        }
    }
}
