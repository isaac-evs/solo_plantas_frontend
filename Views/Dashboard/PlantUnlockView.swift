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

    // Transition states
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

    init(plant: PlantSpecies) {
        _viewModel = StateObject(wrappedValue: PlantUnlockViewModel(plant: plant))
    }

    var body: some View {
        ZStack {
            t.background.ignoresSafeArea()

            // Transition flash
            t.accent.ignoresSafeArea().opacity(overlayOpacity)

            // Faint initial letter
            Text(String(viewModel.plant.name.prefix(1)))
                .font(.system(size: 280, weight: .black, design: .serif))
                .foregroundColor(t.patternColor.opacity(0.07))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 40, y: 40)
                .allowsHitTesting(false)

            VStack(spacing: 0) {

                // --- Header ---
                VStack(spacing: 6) {
                    Text("YOU FOUND IT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(5)
                        .foregroundColor(t.accent.opacity(0.7))

                    Text(viewModel.plant.name)
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundColor(t.textColor)
                        .scaleEffect(appeared ? 1 : 0.85)

                    Text(viewModel.plant.scientificName)
                        .font(.system(size: 13, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(t.textColor.opacity(0.45))
                }
                .padding(.top, 48)
                .opacity(uiOpacity)

                // --- Illustration ---
                ZStack {
                    Ellipse()
                        .fill(t.patternColor.opacity(0.14))
                        .frame(width: 160, height: 160)
                    Image(viewModel.plant.illustrationName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 130)
                        .shadow(color: t.accent.opacity(0.2), radius: 12, x: 0, y: 6)
                }
                .scaleEffect(appeared ? (isTransitioning ? cardScale : 1.0) : 0.7)
                .opacity(appeared ? cardOpacity : 0)
                .padding(.vertical, 24)

                // --- Stage question ---
                VStack(spacing: 10) {
                    Text("HOW FAR ALONG IS IT?")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(4)
                        .foregroundColor(t.textColor.opacity(0.45))

                    Text("Select its current stage")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(t.textColor)
                }
                .opacity(uiOpacity)
                .padding(.bottom, 16)

                // --- Stage selector ---
                VStack(spacing: 10) {
                    ForEach(PlantStage.allCases, id: \.self) { stage in
                        stageRow(stage)
                    }
                }
                .padding(.horizontal, 28)
                .opacity(uiOpacity)

                Spacer()

                // --- Confirm button ---
                Button {
                    guard !isTransitioning else { return }
                    triggerConfirmTransition()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add to my garden")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                    }
                    .foregroundColor(t.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(t.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 28)
                }
                .opacity(uiOpacity)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.1)) {
                appeared = true
            }
            // Celebration haptic on unlock
            notification.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                feedbackHeavy.impactOccurred()
            }
        }
    }

    // MARK: - Stage Row

    private func stageRow(_ stage: PlantStage) -> some View {
        let isSelected = viewModel.selectedStage == stage
        return Button {
            withAnimation(.spring(response: 0.3)) {
                viewModel.selectedStage = stage
            }
            feedbackLight.impactOccurred()
        } label: {
            HStack(spacing: 14) {
                // Icon badge
                ZStack {
                    Circle()
                        .fill(isSelected ? t.accent : t.patternColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: stage.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? t.background : t.textColor.opacity(0.5))
                }

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text(stage.rawValue)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundColor(isSelected ? t.textColor : t.textColor.opacity(0.6))
                    Text(stage.description)
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(t.textColor.opacity(isSelected ? 0.5 : 0.35))
                }

                Spacer()

                // Selected indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(t.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? t.accent.opacity(0.08) : Color.white.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                isSelected ? t.accent.opacity(0.35) : t.accent.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            )
        }
    }

    // MARK: - Transition (same choreography as PlantSelectionView)

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
                overlayOpacity = 0.85
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
