//
//  MainTabBar.swift
//  VirtualGarden
//
// Created by Isaac Vazquez Sandoval on 25/02/26.
//

import SwiftUI

struct MainTabBar: View {
    @EnvironmentObject var appState: AppState

    @State private var appeared = false

    @Environment(\.accessibilityReduceMotion)       private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let feedbackMedium = UIImpactFeedbackGenerator(style: .medium)

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var pillH:     CGFloat { isIpad ? 76  : 64  }
    private var pillW:     CGFloat { isIpad ? 440 : 310 }
    private var iconSize:  CGFloat { isIpad ? 24  : 20  }
    private var labelSize: CGFloat { isIpad ? 13  : 11  }

    var body: some View {
        ZStack {
            // Body
            Capsule()
                .fill(
                    reduceTransparency
                        ? AnyShapeStyle(Color(hex: "#F8F5EF").opacity(0.96))
                        : AnyShapeStyle(.ultraThinMaterial)
                )
                .frame(width: pillW, height: pillH)
                .shadow(color: .black.opacity(0.22), radius: 28, x: 0, y: 10)
                .shadow(color: .black.opacity(0.08), radius: 8,  x: 0, y: 3)
                .shadow(color: .black.opacity(0.04), radius: 2,  x: 0, y: 1)
                .overlay(
                    Capsule()
                        .inset(by: 0.5)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.55), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 0.8
                        )
                )

            // Dividers
            HStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(Color.black.opacity(0.07))
                    .frame(width: 0.75, height: pillH * 0.42)
                Spacer()
                Rectangle()
                    .fill(Color.black.opacity(0.07))
                    .frame(width: 0.75, height: pillH * 0.42)
                Spacer()
            }
            .frame(width: pillW)
            .accessibilityHidden(true)

            // Buttons
            HStack(spacing: 0) {
                tabButton(tab: .home,    icon: "leaf.fill",         label: "Garden")
                tabButton(tab: .scan,    icon: "camera.viewfinder", label: "Scan")
                tabButton(tab: .catalog, icon: "book.closed.fill",  label: "Field Guide")
                tabButton(tab: .assistant, icon: "sparkles.bubble.fill", label: "Chat")
                tabButton(tab: .profile, icon: "person.crop.circle.fill", label: "Profile")
            }
            .frame(width: pillW, height: pillH)
        }
        .frame(width: pillW, height: pillH)
        .padding(.bottom, isIpad ? 12 : 6)
        .scaleEffect(appeared ? 1 : 0.88)
        .opacity(appeared ? 1 : 0)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Main navigation")
        .onAppear {
            withAnimation(
                reduceMotion
                    ? .none
                    : .spring(response: 0.45, dampingFraction: 0.72).delay(0.15)
            ) { appeared = true }
        }
    }

    // Tab Button
    private func tabButton(tab: AppTab, icon: String, label: String) -> some View {
        let isActive = appState.activeTab == tab

        return Button {
            guard !isActive else { return }
            feedbackMedium.impactOccurred()
            appState.switchTab(tab)
        } label: {
            VStack(spacing: isIpad ? 5 : 4) {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(
                        isActive
                            ? AnyShapeStyle(Color.black.opacity(0.85))
                            : AnyShapeStyle(Color.black.opacity(0.35))
                    )
                    .scaleEffect(isActive ? 1.08 : 1.0)
                    .animation(
                        reduceMotion ? .none : .spring(response: 0.28, dampingFraction: 0.6),
                        value: isActive
                    )
                    .accessibilityHidden(true)

                Text(label)
                    .font(.system(size: labelSize, weight: isActive ? .bold : .medium))
                    .foregroundStyle(
                        isActive
                            ? AnyShapeStyle(Color.black.opacity(0.85))
                            : AnyShapeStyle(Color.black.opacity(0.40))
                    )
                    .animation(
                        reduceMotion ? .none : .easeInOut(duration: 0.18),
                        value: isActive
                    )
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .dynamicTypeSize(...DynamicTypeSize.large)
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : [.isButton])
        .accessibilityHint({
            switch tab {
            case .home:    return "Shows your planted garden"
            case .catalog: return "Browse all native plants in the field guide"
            case .profile: return "View account settings and orders"
            case .scan:    return "Opens camera to identify native plants"
            case .assistant: return "Ask the AI botanical assistant for help"
            }
        }())
        .accessibilityRemoveTraits(isActive ? [] : [.isSelected])
    }
}
