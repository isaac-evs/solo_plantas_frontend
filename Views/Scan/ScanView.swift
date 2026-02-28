//
//  ScanView.swift
//  VirtualGarden
//

import SwiftUI
import AVFoundation

struct ScanView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ScanViewModel()

    @State private var cornerPulse = false

    @Environment(\.accessibilityReduceMotion)       private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var frameW: CGFloat { isIpad ? 380 : 260 }
    private var frameH: CGFloat { isIpad ? 500 : 340 }
    private let cornerLen:   CGFloat = 36
    private let cornerThick: CGFloat = 3

    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.cameraService.session)
                .ignoresSafeArea()
                .onAppear  { viewModel.startCamera() }
                .onDisappear { viewModel.stopCamera() }
                .accessibilityLabel("Camera viewfinder")

            VStack(spacing: 0) {

                // Top — live color pill
                HStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Circle()
                            .fill(viewModel.liveColor)
                            .frame(width: isIpad ? 18 : 14, height: isIpad ? 18 : 14)
                            .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1))
                            .accessibilityHidden(true)
                        Text(viewModel.detectedCategoryLabel)
                            .font(.system(size: isIpad ? 15 : 11, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, isIpad ? 20 : 14)
                    .padding(.vertical, isIpad ? 12 : 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .opacity(viewModel.liveColor == .clear ? 0 : 1)
                    .accessibilityLabel("Detected color: \(viewModel.detectedCategoryLabel)")
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)

                Spacer()

                // Scanner frame
                ZStack {
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
                        .accessibilityHidden(true)

                    ZStack {
                        cornerBracket(rotation: 0)  .offset(x: -frameW/2, y: -frameH/2)
                        cornerBracket(rotation: 90) .offset(x:  frameW/2, y: -frameH/2)
                        cornerBracket(rotation: 180).offset(x:  frameW/2, y:  frameH/2)
                        cornerBracket(rotation: 270).offset(x: -frameW/2, y:  frameH/2)
                    }
                    .scaleEffect(cornerPulse ? 1.03 : 1.0)
                    .animation(
                        reduceMotion ? .none : .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: cornerPulse
                    )
                    .onAppear { if !reduceMotion { cornerPulse = true } }
                    .accessibilityHidden(true)

                    if viewModel.isScanning {
                        ScanLineView(frameH: frameH, frameW: frameW)
                            .accessibilityHidden(true)
                    }

                    Circle()
                        .fill(viewModel.liveColor == .clear ? Color.white.opacity(0.6) : viewModel.liveColor)
                        .frame(width: isIpad ? 22 : 16, height: isIpad ? 22 : 16)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.3), radius: 4)
                        .scaleEffect(viewModel.isScanning ? 1.4 : 1.0)
                        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.isScanning)
                        .accessibilityHidden(true)
                }
                .frame(width: frameW, height: frameH)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Scanning frame. Point at a leaf or flower and fill the frame.")

                Spacer()

                // Bottom panel
                VStack(spacing: isIpad ? 20 : 16) {
                    VStack(spacing: isIpad ? 6 : 4) {
                        Text(viewModel.isScanning ? "Extracting dominant color" : "Center a leaf or flower")
                            .font(.system(size: isIpad ? 22 : 16, weight: .semibold, design: .serif))
                            .foregroundColor(.white)
                        Text(viewModel.isScanning ? "Hold still…" : "Fill the frame for best results")
                            .font(.system(size: isIpad ? 17 : 12, design: .serif))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        viewModel.isScanning
                            ? "Extracting dominant color. Hold still."
                            : "Center a leaf or flower. Fill the frame for best results."
                    )

                    Button {
                        let ownedIDs = Set(appState.plantedDates.keys)
                        viewModel.performScan(unlockedIDs: ownedIDs)
                    } label: {
                        HStack(spacing: 10) {
                            if viewModel.isScanning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .scaleEffect(0.8)
                                    .accessibilityHidden(true)
                            } else {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: isIpad ? 20 : 16, weight: .semibold))
                                    .accessibilityHidden(true)
                            }
                            Text(viewModel.isScanning ? "Scanning…" : "Identify Plant")
                                .font(.system(size: isIpad ? 20 : 16, weight: .semibold, design: .serif))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: isIpad ? 70 : 54)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: isIpad ? 18 : 14, style: .continuous))
                    }
                    .disabled(viewModel.isScanning)
                    .opacity(viewModel.isScanning ? 0.7 : 1.0)
                    .animation(reduceMotion ? .none : .easeInOut(duration: 0.2), value: viewModel.isScanning)
                    .accessibilityLabel(viewModel.isScanning ? "Scanning in progress" : "Identify Plant")
                    .accessibilityHint(viewModel.isScanning ? "Please wait" : "Analyzes the color of the plant in frame")
                }
                .padding(.horizontal, isIpad ? 36 : 24)
                .padding(.vertical, isIpad ? 32 : 24)
                .background(
                    reduceTransparency
                        ? AnyView(RoundedRectangle(cornerRadius: isIpad ? 32 : 24, style: .continuous).fill(Color.black.opacity(0.85)))
                        : AnyView(RoundedRectangle(cornerRadius: isIpad ? 32 : 24, style: .continuous).fill(.ultraThinMaterial))
                )
                .padding(.horizontal, isIpad ? 32 : 20)
                .padding(.bottom, isIpad ? 56 : 40)
            }
        }
        .sheet(isPresented: $viewModel.scanComplete, onDismiss: {
            viewModel.isScanning = false
        }) {
            MatchPlantView(matchedPlants: viewModel.matchedPlants)
        }
    }

    private func cornerBracket(rotation: Double) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: cornerLen, height: cornerThick)
                .offset(x: cornerLen / 2, y: cornerThick / 2)
            Rectangle()
                .fill(Color.white)
                .frame(width: cornerThick, height: cornerLen)
                .offset(x: cornerThick / 2, y: cornerLen / 2)
        }
        .rotationEffect(.degrees(rotation))
    }
}

private struct ScanLineView: View {
    let frameH: CGFloat
    let frameW: CGFloat
    @State private var offset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [.clear, .green.opacity(0.8), .clear],
                startPoint: .leading, endPoint: .trailing
            ))
            .frame(width: frameW - 20, height: 2)
            .offset(y: offset)
            .onAppear {
                offset = -frameH / 2 + 10
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: true)) {
                    offset = frameH / 2 - 10
                }
            }
    }
}
