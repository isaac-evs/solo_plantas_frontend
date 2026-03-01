//
//  PlantUnlockView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 19/02/26.
//

import SwiftUI

struct PlantUnlockView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: PlantUnlockViewModel

    // States
    @State private var appeared = false
    @State private var isTransitioning = false
    @State private var cardScale: CGFloat = 1.0
    @State private var cardOpacity: Double = 1.0
    @State private var overlayOpacity: Double = 0.0
    @State private var uiOpacity: Double = 1.0

    private let feedbackHeavy  = UIImpactFeedbackGenerator(style: .heavy)
    private let feedbackMedium = UIImpactFeedbackGenerator(style: .medium)
    private let feedbackLight  = UIImpactFeedbackGenerator(style: .light)
    private let feedbackSoft   = UIImpactFeedbackGenerator(style: .soft)
    private let notification   = UINotificationFeedbackGenerator()

    private var t: SeedPacketTheme { seedTheme(for: viewModel.plant.id) }
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    
    private let s: CGFloat = 1.35

    init(plant: PlantSpecies) {
        _viewModel = StateObject(wrappedValue: PlantUnlockViewModel(plant: plant))
    }

    var body: some View {
        ZStack {
            t.background.ignoresSafeArea()

            t.accent.ignoresSafeArea().opacity(overlayOpacity)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // --- Header ---
                    VStack(spacing: 8) {
                        Text("YOU FOUND IT")
                            .font(.system(size: 10 * s, weight: .bold, design: .monospaced))
                            .tracking(5)
                            .foregroundColor(t.accent.opacity(0.8))
                            .accessibilityAddTraits(.isHeader)

                        Text(viewModel.plant.name)
                            .font(.system(size: 38 * (s * 0.9), weight: .bold, design: .serif))
                            .foregroundColor(t.textColor)
                            .scaleEffect(appeared ? 1 : 0.85)

                        Text(viewModel.plant.scientificName)
                            .font(.system(size: 13 * s, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(t.textColor.opacity(0.55))
                    }
                    .padding(.top, isIpad ? 48 : 68)
                    .opacity(uiOpacity)
                    .accessibilityElement(children: .combine)

                    // --- Illustration ---
                    ZStack {
                        Circle()
                            .fill(t.patternColor.opacity(0.14))
                            .frame(width: 200, height: 200)
                        
                        Image(viewModel.plant.illustrationName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 176, height: 176) 
                            .clipShape(Circle())
                            .shadow(color: t.accent.opacity(0.2), radius: 12, x: 0, y: 6)
                    }
                    .scaleEffect(appeared ? (isTransitioning ? cardScale : 1.0) : 0.7)
                    .opacity(appeared ? cardOpacity : 0)
                    .padding(.vertical, 32)
                    .accessibilityHidden(true)

                    // --- Stage question ---
                    VStack(spacing: 12) {
                        Text("HOW FAR ALONG IS IT?")
                            .font(.system(size: 10 * s, weight: .bold, design: .monospaced))
                            .tracking(4)
                            .foregroundColor(t.textColor.opacity(0.55))

                        Text("Select its current stage")
                            .font(.system(size: 20 * s, weight: .bold, design: .serif))
                            .foregroundColor(t.textColor)
                    }
                    .opacity(uiOpacity)
                    .padding(.bottom, 24)
                    .accessibilityElement(children: .combine)

                    // --- Stage ---
                    VStack(spacing: 14) {
                        ForEach(PlantStage.allCases, id: \.self) { stage in
                            stageRow(stage)
                        }
                    }
                    .padding(.horizontal, 28)
                    .opacity(uiOpacity)

                    Spacer(minLength: 40)

                    // --- Confirm button ---
                    Button {
                        guard !isTransitioning else { return }
                        triggerConfirmTransition()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 14 * s, weight: .semibold))
                            Text("Add to my garden")
                                .font(.system(size: 16 * s, weight: .bold, design: .serif))
                        }
                        .foregroundColor(t.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(t.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(.horizontal, 28)
                    }
                    .opacity(uiOpacity)
                    .padding(.bottom, 40)
                    .accessibilityHint("Saves the plant to your garden")
                }
                .frame(minHeight: UIScreen.main.bounds.height)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.1)) {
                appeared = true
            }
            notification.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                feedbackHeavy.impactOccurred()
            }
        }
    }

    // Stage Row

    private func stageRow(_ stage: PlantStage) -> some View {
        let isSelected = viewModel.selectedStage == stage
        return Button {
            withAnimation(.spring(response: 0.3)) {
                viewModel.selectedStage = stage
            }
            feedbackLight.impactOccurred()
        } label: {
            HStack(spacing: 16) {
                // Icon badge
                ZStack {
                    Circle()
                        .fill(isSelected ? t.accent : t.patternColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: stage.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? t.background : t.textColor.opacity(0.6))
                }

                // Label
                VStack(alignment: .leading, spacing: 4) {
                    Text(stage.rawValue)
                        .font(.system(size: 15 * s, weight: .bold, design: .serif))
                        .foregroundColor(isSelected ? t.textColor : t.textColor.opacity(0.7))
                    Text(stage.description)
                        .font(.system(size: 11 * s, design: .serif))
                        .foregroundColor(t.textColor.opacity(isSelected ? 0.6 : 0.45))
                }

                Spacer()

                // Selected indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(t.accent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? t.accent.opacity(0.08) : Color.white.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                isSelected ? t.accent.opacity(0.4) : t.accent.opacity(0.1),
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .accessibilityLabel("\(stage.rawValue) stage")
        .accessibilityHint(stage.description)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // Transition

    private func triggerConfirmTransition() {
        isTransitioning = true
        feedbackHeavy.impactOccurred()

        withAnimation(.easeOut(duration: 0.25)) { uiOpacity = 0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            feedbackMedium.impactOccurred()
            withAnimation(.spring(response: 0.18, dampingFraction: 0.4)) { cardScale = 0.93 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            feedbackSoft.impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) { cardScale = 1.0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            feedbackLight.impactOccurred()
            withAnimation(.easeIn(duration: 0.15)) {
                overlayOpacity = 1.0
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                cardScale = 3.5
                cardOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            viewModel.confirm(appState: appState)
            dismiss()
            appState.currentScreen = .plantHome
        }
    }
}
