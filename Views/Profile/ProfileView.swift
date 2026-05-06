import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cart: CartManager
    @AppStorage("profileUsername") private var storedUsername: String = ""
    @AppStorage("profileIconName") private var storedIcon: String = ""
    @State private var activeOrdersCount: Int = 0

    private let accent     = Color(hex: "#4A7C59")
    private let dark       = Color(hex: "#1A2E1A")
    private let sand       = Color(hex: "#F5F0E8")
    private let cardWhite  = Color.white.opacity(0.72)

    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        NavigationView {
            ZStack {
                // ── Background ──
                sand.ignoresSafeArea()

                GeometryReader { geo in
                    // Soft botanical blobs
                    Circle()
                        .fill(accent.opacity(0.10))
                        .frame(width: geo.size.width * 0.9)
                        .offset(x: geo.size.width * 0.35, y: -geo.size.width * 0.3)
                        .blur(radius: 70)
                    Circle()
                        .fill(Color(hex: "#D4A017").opacity(0.07))
                        .frame(width: geo.size.width * 0.7)
                        .offset(x: -geo.size.width * 0.15, y: geo.size.height * 0.6)
                        .blur(radius: 60)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Top bar ──
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Garden")
                                    .font(.system(size: 15, weight: .semibold))
                                    .tracking(3)
                                    .foregroundColor(accent.opacity(0.7))
                                Text("Profile")
                                    .font(.system(size: isIpad ? 54 : 42, weight: .heavy))
                                    .foregroundColor(dark)
                            }
                            Spacer()
                            logOutButton
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, isIpad ? 40 : 24)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                        .animation(.easeOut(duration: 0.4), value: appeared)

                        // ── Hero identity card ──
                        heroCard
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.easeOut(duration: 0.45).delay(0.08), value: appeared)

                        // ── Stats row ──
                        statsRow
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.easeOut(duration: 0.45).delay(0.15), value: appeared)

                        // ── Section label ──
                        Text("Account".uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .tracking(3)
                            .foregroundColor(dark.opacity(0.35))
                            .padding(.horizontal, 24)
                            .padding(.top, 32)
                            .padding(.bottom, 12)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.22), value: appeared)

                        // ── Menu rows ──
                        menuSection
                            .padding(.horizontal, 24)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)

                        // ── Botanical quote footer ──
                        botanicalFooter
                            .padding(.top, 40)
                            .padding(.bottom, 48)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(0.35), value: appeared)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if storedUsername.isEmpty {
                    storedUsername = ["HappyRadish", "AngryTomato", "SleepyCactus", "BraveAgave", "MysticFern", "ZenBonsai", "CosmicMonstera", "WildOrchid", "ChubbySucculent", "NeonPothos"].randomElement() ?? "HappyRadish"
                }
                if storedIcon.isEmpty {
                    storedIcon = ["leaf.fill", "tree.fill", "ant.fill", "ladybug.fill", "bird.fill", "tortoise.fill", "pawprint.fill"].randomElement() ?? "leaf.fill"
                }
                Task { await fetchActiveOrders() }
                withAnimation { appeared = true }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Hero card
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            // Deep green background with texture dots
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#2D5A3D"), Color(hex: "#1A3626")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: isIpad ? 220 : 180)

            // Decorative dots — matches SeedPacketCard motif
            Canvas { ctx, size in
                let xs: [CGFloat] = [20,80,150,220,290,350,60,130,200,270,330,40,110,180,250,310,70,140]
                let ys: [CGFloat] = [20,50,25,55,20,45,90,80,100,85,110,140,130,150,125,145,170,160]
                let ds: [CGFloat] = [5,9,4,12,6,8,5,10,7,11,5,8,6,10,5,7,9,4]
                for i in 0..<18 {
                    var path = Path()
                    path.addEllipse(in: CGRect(x: xs[i], y: ys[i], width: ds[i], height: ds[i]))
                    ctx.fill(path, with: .color(.white.opacity(0.07)))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .accessibilityHidden(true)

            // Large illustrative leaf ghost top-right
            Image(systemName: storedIcon.isEmpty ? "leaf.fill" : storedIcon)
                .resizable()
                .scaledToFit()
                .frame(width: isIpad ? 160 : 130, height: isIpad ? 160 : 130)
                .foregroundColor(.white)
                .opacity(0.12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(24)
                .accessibilityHidden(true)

            // Content
            HStack(alignment: .bottom, spacing: 18) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: "#4A7C59"))
                        .frame(width: isIpad ? 80 : 66, height: isIpad ? 80 : 66)
                    Image(systemName: storedIcon.isEmpty ? "leaf.fill" : storedIcon)
                        .resizable()
                        .scaledToFit()
                        .padding(16)
                        .foregroundColor(.white)
                        .frame(width: isIpad ? 80 : 66, height: isIpad ? 80 : 66)
                        .clipShape(Circle())
                }
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 5) {
                    Text(storedUsername.isEmpty ? "HappyRadish" : storedUsername)
                        .font(.system(size: isIpad ? 26 : 22, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#7AAF8E"))
                        Text("Native plant enthusiast")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()
            }
            .padding(24)
        }
        .shadow(color: dark.opacity(0.18), radius: 24, x: 0, y: 12)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Stats row
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "staroflife.fill",
                iconColor: Color(hex: "#4A7C59"),
                value: "\(appState.plantedDates.count)",
                label: "Seeds Planted"
            )
            statCard(
                icon: "shippingbox.fill",
                iconColor: Color(hex: "#C8A800"),
                value: "\(activeOrdersCount)",
                label: "Active Orders"
            )
            statCard(
                icon: "heart.fill",
                iconColor: Color(hex: "#E05C00"),
                value: "\(appState.plantedDates.count > 0 ? "🌿" : "—")",
                label: "Ecosystem"
            )
        }
    }

    @ViewBuilder
    private func statCard(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            Text(value)
                .font(.system(size: isIpad ? 28 : 24, weight: .heavy))
                .foregroundColor(dark)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(dark.opacity(0.45))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(dark.opacity(0.05), lineWidth: 1)
                )
        )
        .shadow(color: dark.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Menu section
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var menuSection: some View {
        VStack(spacing: 2) {
            menuRow(
                icon: "shippingbox.fill",
                iconColor: Color(hex: "#4A7C59"),
                label: "Order History",
                sublabel: "Track your botanical purchases",
                destination: AnyView(OrderHistoryView()),
                isFirst: true,
                isLast: true
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(dark.opacity(0.05), lineWidth: 1)
                )
        )
        .shadow(color: dark.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private func menuRow(
        icon: String,
        iconColor: Color,
        label: String,
        sublabel: String,
        destination: AnyView,
        isFirst: Bool,
        isLast: Bool
    ) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(dark)
                    Text(sublabel)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(dark.opacity(0.45))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(dark.opacity(0.25))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Footer
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var botanicalFooter: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(accent.opacity(0.2))
                    .frame(height: 1)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11))
                    .foregroundColor(accent.opacity(0.4))
                Rectangle()
                    .fill(accent.opacity(0.2))
                    .frame(height: 1)
            }
            .padding(.horizontal, 48)

            Text("Every seed planted is a future forest.")
                .font(.system(size: 13, weight: .regular))
                .italic()
                .foregroundColor(dark.opacity(0.35))
                .multilineTextAlignment(.center)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Log out button
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var logOutButton: some View {
        Button {
            KeychainHelper.shared.deleteToken()
            UserDefaults.standard.removeObject(forKey: "currentUserId")
            cart.items.removeAll()
            appState.plantedDates = PersistenceService.shared.loadGarden()
            appState.routeAfterSplash()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                Text("Log Out")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.red.opacity(0.85))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(Color.red.opacity(0.08))
            )
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Network
    // ─────────────────────────────────────────────────────────────

    private func fetchActiveOrders() async {
        do {
            struct BriefOrder: Decodable { let status: String }
            let response: [BriefOrder]? = try await NetworkManager.shared.request(endpoint: "/orders", method: "GET")
            if let orders = response {
                activeOrdersCount = orders.filter { $0.status == "pending" }.count
            }
        } catch {
            print("Failed to fetch active orders count: \(error)")
        }
    }
}