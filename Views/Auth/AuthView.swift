import SwiftUI

// MARK: - AuthView (unified Login + Sign Up)

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @AppStorage("isDriverMode") private var isDriverMode: Bool = false

    // which tab is active
    @State private var isSignUp: Bool
    // entrance animation
    @State private var appeared = false
    // success burst
    @State private var showSuccess = false
    // field focus
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private let accent   = Color(hex: "#4A7C59")
    private let dark     = Color(hex: "#1A2E1A")
    private let bg       = Color(hex: "#F5F0E8")
    private let cardBg   = Color.white

    // Allow navigating directly to sign-up tab
    init(startOnSignUp: Bool = false) {
        _isSignUp = State(initialValue: startOnSignUp)
    }

    var body: some View {
        ZStack {
            // ── Background ────────────────────────────────────────
            bg.ignoresSafeArea()

            GeometryReader { geo in
                // Top decorative blob
                Circle()
                    .fill(accent.opacity(0.10))
                    .frame(width: geo.size.width * 0.9)
                    .offset(x: geo.size.width * 0.4, y: -geo.size.height * 0.15)
                    .blur(radius: 60)

                // Bottom blob
                Circle()
                    .fill(accent.opacity(0.07))
                    .frame(width: geo.size.width * 0.7)
                    .offset(x: -50, y: geo.size.height * 0.72)
                    .blur(radius: 50)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            // ── Main card ─────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: isIpad ? 80 : 60)

                    // Logo / brand mark
                    brandMark
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.05), value: appeared)

                    // Card
                    VStack(spacing: 0) {
                        tabSwitcher
                            .padding(.top, 28)
                            .padding(.horizontal, 24)

                        formFields
                            .padding(.top, 24)
                            .padding(.horizontal, 24)

                        errorBanner
                            .padding(.top, 12)
                            .padding(.horizontal, 24)

                        primaryButton
                            .padding(.top, 20)
                            .padding(.horizontal, 24)

                        driverToggle
                            .padding(.top, 24)
                            .padding(.bottom, 32)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(cardBg.opacity(0.88))
                            .shadow(color: dark.opacity(0.08), radius: 24, x: 0, y: 8)
                    )
                    .padding(.horizontal, isIpad ? 80 : 24)
                    .frame(maxWidth: isIpad ? 520 : .infinity)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    .animation(.spring(response: 0.65, dampingFraction: 0.78).delay(0.12), value: appeared)

                    Spacer(minLength: 60)
                }
                .frame(maxWidth: .infinity)
            }
            // Tap background to dismiss keyboard
            .onTapGesture { focusedField = nil }

            // ── Success burst overlay ─────────────────────────────
            if showSuccess {
                successOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                    .zIndex(20)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: isSignUp)
    }

    // MARK: Brand

    @ViewBuilder
    private var brandMark: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: isIpad ? 96 : 72, height: isIpad ? 96 : 72)
                Image(systemName: "leaf.fill")
                    .font(.system(size: isIpad ? 38 : 28, weight: .semibold))
                    .foregroundColor(accent)
            }

            Text("Solo Plantas")
                .font(.system(size: isIpad ? 36 : 26, weight: .heavy))
                .foregroundColor(dark)

            Text("Your botanical companion")
                .font(.system(size: isIpad ? 18 : 14, weight: .regular))
                .foregroundColor(dark.opacity(0.45))
        }
        .padding(.bottom, 28)
    }

    // MARK: Tab switcher

    @ViewBuilder
    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            tabButton(label: "Log In",   selected: !isSignUp) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isSignUp = false
                    viewModel.errorMessage = nil
                    focusedField = nil
                }
            }
            tabButton(label: "Sign Up",  selected: isSignUp) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isSignUp = true
                    viewModel.errorMessage = nil
                    focusedField = nil
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(bg)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func tabButton(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: isIpad ? 18 : 15, weight: .semibold))
                .foregroundColor(selected ? .white : dark.opacity(0.45))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(selected ? accent : Color.clear)
                        .shadow(color: selected ? accent.opacity(0.3) : .clear, radius: 8, y: 4)
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selected)
        }
        .padding(4)
    }

    // MARK: Form fields

    @ViewBuilder
    private var formFields: some View {
        VStack(spacing: 14) {
            // Email
            HStack(spacing: 12) {
                Image(systemName: "envelope")
                    .foregroundColor(accent.opacity(0.7))
                    .frame(width: 20)
                TextField("Email address", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .font(.system(size: isIpad ? 18 : 16))
                    .foregroundColor(dark)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(fieldBackground(focused: focusedField == .email))

            // Password
            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .foregroundColor(accent.opacity(0.7))
                    .frame(width: 20)
                SecureField("Password", text: $viewModel.password)
                    .font(.system(size: isIpad ? 18 : 16))
                    .foregroundColor(dark)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil; triggerAction() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(fieldBackground(focused: focusedField == .password))
        }
    }

    @ViewBuilder
    private func fieldBackground(focused: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(bg)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(focused ? accent : Color.clear, lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.2), value: focused)
    }

    // MARK: Error banner

    @ViewBuilder
    private var errorBanner: some View {
        if let err = viewModel.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text(err)
                    .font(.system(size: isIpad ? 15 : 13, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "#C0392B"))
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: Primary button

    @ViewBuilder
    private var primaryButton: some View {
        let disabled = viewModel.isLoading
                    || viewModel.email.trimmingCharacters(in: .whitespaces).isEmpty
                    || viewModel.password.isEmpty

        Button(action: { triggerAction() }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accent)
                    .overlay(
                        LinearGradient(
                            colors: [.white.opacity(0.0), .white.opacity(0.07), .white.opacity(0.0)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    )
                    .shadow(color: accent.opacity(0.35), radius: 12, y: 6)

                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(isSignUp ? "Create Account" : "Log In")
                        .font(.system(size: isIpad ? 20 : 17, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIpad ? 60 : 52)
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: disabled)
        .scaleEffect(viewModel.isLoading ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isLoading)
    }

    // MARK: Driver toggle

    @ViewBuilder
    private var driverToggle: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isDriverMode.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: isDriverMode ? "shippingbox.fill" : "shippingbox")
                    .font(.system(size: 13, weight: .semibold))
                Text(isDriverMode ? "Courier Mode Active" : "I'm a Botanical Courier")
                    .font(.system(size: isIpad ? 15 : 13, weight: .semibold))
            }
            .foregroundColor(isDriverMode ? accent : dark.opacity(0.4))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isDriverMode ? accent.opacity(0.10) : Color.clear)
                    .overlay(
                        Capsule().stroke(
                            isDriverMode ? accent.opacity(0.3) : dark.opacity(0.12),
                            lineWidth: 1
                        )
                    )
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isDriverMode)
        }
    }

    // MARK: Success overlay (register only)

    @ViewBuilder
    private var successOverlay: some View {
        Color.black.opacity(0.45).ignoresSafeArea()

        VStack(spacing: 20) {
            // Animated checkmark circle
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 110, height: 110)

                Circle()
                    .stroke(accent, lineWidth: 3)
                    .frame(width: 90, height: 90)

                Image(systemName: "checkmark")
                    .font(.system(size: 38, weight: .heavy))
                    .foregroundColor(accent)
            }

            VStack(spacing: 6) {
                Text("Welcome! 🌱")
                    .font(.system(size: isIpad ? 34 : 28, weight: .heavy))
                    .foregroundColor(.white)

                Text("Your garden awaits.")
                    .font(.system(size: isIpad ? 18 : 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
            }
        }
        .padding(44)
        .background(Color(hex: "#1A2E1A"))
        .cornerRadius(32)
        .shadow(color: .black.opacity(0.35), radius: 40, y: 20)
    }

    // MARK: Action

    private func triggerAction() {
        focusedField = nil
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            if isSignUp {
                await viewModel.register(appState: appState)
                // If no error after register → show success burst + haptics
                if viewModel.errorMessage == nil {
                    let success = UINotificationFeedbackGenerator()
                    success.notificationOccurred(.success)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showSuccess = true
                    }
                    // Let the animation breathe before navigating
                    try? await Task.sleep(nanoseconds: 2_200_000_000)
                    withAnimation { showSuccess = false }
                }
            } else {
                await viewModel.login(appState: appState)
                if viewModel.errorMessage != nil {
                    // Error haptic on failure
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
}
