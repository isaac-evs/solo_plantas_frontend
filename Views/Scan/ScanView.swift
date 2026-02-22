//
//  ScanView.swift
// VirtualGarden
//
// Created by Isaac Vazquez Sandoval on 14/02/26.
//

import SwiftUI
import AVFoundation

struct ScanView: View {
    @EnvironmentObject var appState: AppState
    
    @StateObject private var viewModel = ScanViewModel()
    @State private var showMatchSheet = false
    
    var body: some View {
        ZStack {
            // Camera feed
            CameraPreview(session: viewModel.cameraService.session)
                .ignoresSafeArea()
                .onAppear{ viewModel.startCamera() }
                .onDisappear { viewModel.stopCamera() }
            
            // UI Overlay
            VStack {
                HStack {
                    Button(action: {
                        appState.currentScreen = .catalog
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Scanner
                ZStack {
                    // Frame
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(viewModel.isScanning ? Color.green : Color.white, lineWidth: 3)
                        .frame(width: 250, height: 350)
                        .shadow(color: viewModel.isScanning ? .green : .clear, radius: 10)
                    
                    Circle()
                        .fill(viewModel.liveColor)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                    
                    if viewModel.isScanning {
                        Rectangle()
                            .fill(Color.green.opacity(0.5))
                            .frame(width: 250, height: 2)
                            .offset(y: -170)
                            .alignmentGuide(VerticalAlignment.center) { _ in 0 }
                            .modifier(ScannerAnimationModifier())
                    }
                }
                
                Spacer()
                
                // Bottom Panel
                VStack(spacing: 15) {
                    Text(viewModel.isScanning ? "Exctracting dominant color.." : "Center a leaf or flower")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Button(action: {
                        viewModel.performScan(unlockedIDs: appState.unlockedPlantIDs)
                    }) {
                        Text (viewModel.isScanning ? "Scanning..." : "Identify Plant")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.isScanning)
                }
                .padding(24)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
                .padding()
            }
        }
        // Match Sheet
        .sheet(isPresented: $viewModel.scanComplete, onDismiss:{
            viewModel.isScanning = false
        }){
            MatchPlantView(matchedPlants: viewModel.matchedPlants)
        }
    }
}

struct ScannerAnimationModifier: ViewModifier {
    @State private var offset: CGFloat = -170
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear{
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: true)) {
                    offset = 170
                }
            }
    }
}
