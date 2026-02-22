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
    
    @State private var session = AVCaptureSession()
    @State private var isScanning = false
    @State private var scanComplete = false
    @State private var showMatchSheet = false
    
    var body: some View {
        ZStack {
            // Camera feed
            CameraPreview(session: session)
                .ignoresSafeArea()
                .onAppear{ startCamera() }
                .onDisappear { session.stopRunning() }
            
            // UI Overlay
            VStack {
                HStack {
                    Button(action: {
                        AppState.currentScreen = .catalog
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
                
                // Scanner Frame
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isScanning ? Color.green : Color.white, lineWidth: 3)
                        .frame(width: 250, height: 350)
                        .shadow(color: isScanning ? .green : .clear, radius: 10)
                    if isScanning {
                        Rectangle()
                            .fill(Color.green.opacity(0.5))
                            .frame(width: 250, height: 2)
                            .offset(y: -170)
                            .allignmentGuide(VerticalAlignment.center) { _ in 0 }
                            .modifier(ScannerAnimationModifier())
                    }
                }
                
                Spacer()
                
                // Bottom Panel
                VStack(spacing: 15) {
                    Text(isScanning ? "Anlyzing leaves and structure..." : "Scan a leaf")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Button(action: startScan) {
                        Text (isScanning ? "Scanning..." : "Identify Plant")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .disables(isScanning)
                }
                .padding(24)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
                .padding()
            }
        }
        // Match Sheet
        .sheet(is Presented: $showMatchSheet){
            MatchPlantView()
        }
    }
    
    // Camera Setup
    private func startCamera(){
        DispatchQueue.global(qos: .userInitiated).async{
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .vide, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }
            
            if session.canAddInput(input){
                session.addInput(input)
                session.startRunning()
            }
        }
    }
    
    private func startScan(){
        isScanning = true
        DispatchQueue.main.asyncAfter( deadline: .now() + 2.5){
            isScanning = false
            scanComplete = true
            showMatchSheet = true
        }
    }
}

// Scan Animation mofifier
struct ScannerAnimationModifier: ViewModifier {
    @State private var offset: CGFloat = -170
}
