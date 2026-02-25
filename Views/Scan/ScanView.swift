//
//  ScanView.swift
// VirtualGarden
//
// Created by Isaac Vazquez Sandoval on 14/02/26.
//
//
//  ScanView.swift
//  VirtualGarden
//

import SwiftUI
import AVFoundation

struct ScanView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ScanViewModel()

    // Corner animation
    @State private var cornerPulse = false

    private let frameW: CGFloat = 260
    private let frameH: CGFloat = 340
    private let cornerLen: CGFloat = 28
    private let cornerThick: CGFloat = 3

    var body: some View {
        ZStack {
            // Camera
            CameraPreview(session: viewModel.cameraService.session)
                .ignoresSafeArea()
                .onAppear  { viewModel.startCamera() }
                .onDisappear { viewModel.stopCamera() }

            VStack(spacing: 0) {

                // --- Top bar ---
                HStack {
                    Button {
                        appState.currentScreen = .catalog
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()

                    // Live color swatch
                    HStack(spacing: 8) {
                        Circle()
                            .fill(viewModel.liveColor)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1))
                        Text(viewModel.detectedCategoryLabel)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .opacity(viewModel.liveColor == .clear ? 0 : 1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)

                Spacer()

                // --- Scanner frame ---
                ZStack {
                    // Darkened overlay outside frame
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .mask(
                            Rectangle()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .frame(width: frameW, height: frameH)
                                        .blendMode(.destinationOut)
                                )
                        )
                        .allowsHitTesting(false)

                    // Corner brackets
                    ZStack {
                        // Top-left
                        cornerBracket(rotation: 0)
                            .offset(x: -frameW/2, y: -frameH/2)
                        // Top-right
                        cornerBracket(rotation: 90)
                            .offset(x:  frameW/2, y: -frameH/2)
                        // Bottom-right
                        cornerBracket(rotation: 180)
                            .offset(x:  frameW/2, y:  frameH/2)
                        // Bottom-left
                        cornerBracket(rotation: 270)
                            .offset(x: -frameW/2, y:  frameH/2)
                    }
                    .scaleEffect(cornerPulse ? 1.03 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: cornerPulse
                    )
                    .onAppear { cornerPulse = true }

                    // Scan line — only when actively scanning
                    if viewModel.isScanning {
                        ScanLineView(frameH: frameH, frameW: frameW)
                    }

                    // Center crosshair dot
                    Circle()
                        .fill(viewModel.liveColor == .clear ? Color.white.opacity(0.6) : viewModel.liveColor)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.3), radius: 4)
                        .scaleEffect(viewModel.isScanning ? 1.4 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isScanning)
                }
                .frame(width: frameW, height: frameH)

                Spacer()

                // --- Bottom panel ---
                VStack(spacing: 16) {
                    // Instruction text
                    VStack(spacing: 4) {
                        Text(viewModel.isScanning ? "Extracting dominant color" : "Center a leaf or flower")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundColor(.white)
                        Text(viewModel.isScanning ? "Hold still…" : "Fill the frame for best results")
                            .font(.system(size: 12, design: .serif))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    // Scan button
                    Button {
                        let ownedIDs = Set(appState.plantedDates.keys)
                        viewModel.performScan(unlockedIDs: ownedIDs)
                    } label: {
                        HStack(spacing: 10) {
                            if viewModel.isScanning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text(viewModel.isScanning ? "Scanning…" : "Identify Plant")
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(viewModel.isScanning)
                    .opacity(viewModel.isScanning ? 0.7 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isScanning)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .background(.ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $viewModel.scanComplete, onDismiss: {
            viewModel.isScanning = false
        }) {
            MatchPlantView(matchedPlants: viewModel.matchedPlants)
        }
    }

    // MARK: - Corner bracket

    private func cornerBracket(rotation: Double) -> some View {
        ZStack {
            // Horizontal arm
            Rectangle()
                .fill(Color.white)
                .frame(width: cornerLen, height: cornerThick)
                .offset(x: cornerLen / 2, y: cornerThick / 2)
            // Vertical arm
            Rectangle()
                .fill(Color.white)
                .frame(width: cornerThick, height: cornerLen)
                .offset(x: cornerThick / 2, y: cornerLen / 2)
        }
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Scan Line (self-contained with own state)

private struct ScanLineView: View {
    let frameH: CGFloat
    let frameW: CGFloat

    @State private var offset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, .green.opacity(0.8), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: frameW - 20, height: 2)
            .offset(y: offset)
            .onAppear {
                offset = -frameH / 2 + 10
                withAnimation(
                    .linear(duration: 1.6)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = frameH / 2 - 10
                }
            }
        }
}
