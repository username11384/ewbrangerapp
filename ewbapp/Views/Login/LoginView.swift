import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: LoginViewModel

    init() {
        _viewModel = StateObject(wrappedValue: LoginViewModel(
            authManager: AppEnvironment.shared.authManager,
            persistence: AppEnvironment.shared.persistence
        ))
    }

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // ── Hero ─────────────────────────────────────────
                        LoginHeroView(
                            width: geo.size.width,
                            isCompact: viewModel.selectedRanger != nil
                        )

                        // ── Content ───────────────────────────────────────
                        VStack(spacing: DSSpace.xxl) {

                            // Ranger selection
                            VStack(alignment: .leading, spacing: DSSpace.md) {
                                Text("SELECT RANGER")
                                    .font(DSFont.badge)
                                    .foregroundStyle(Color.dsInk3)
                                    .tracking(1.2)

                                HStack(spacing: DSSpace.sm) {
                                    ForEach(viewModel.rangers, id: \.id) { ranger in
                                        RangerAvatarCard(
                                            ranger: ranger,
                                            isSelected: viewModel.selectedRanger?.id == ranger.id
                                        ) {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                viewModel.selectRanger(ranger)
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                withAnimation { proxy.scrollTo("pin", anchor: .bottom) }
                                            }
                                        }
                                    }
                                }
                            }

                            // PIN entry
                            if viewModel.selectedRanger != nil {
                                VStack(spacing: DSSpace.lg) {
                                    Text("ENTER PIN")
                                        .font(DSFont.badge)
                                        .foregroundStyle(Color.dsInk3)
                                        .tracking(1.2)

                                    // PIN dots
                                    HStack(spacing: 18) {
                                        ForEach(0..<4, id: \.self) { i in
                                            let filled = i < viewModel.enteredPIN.count
                                            Circle()
                                                .fill(filled ? Color.dsPrimary : Color.clear)
                                                .frame(width: 15, height: 15)
                                                .overlay(
                                                    Circle().strokeBorder(
                                                        filled ? Color.dsPrimary : Color.dsDivider,
                                                        lineWidth: 1.5
                                                    )
                                                )
                                                .scaleEffect(filled ? 1.2 : 1.0)
                                                .animation(
                                                    .spring(response: 0.2, dampingFraction: 0.6),
                                                    value: filled
                                                )
                                        }
                                    }

                                    PINKeypad(
                                        onDigit: { viewModel.appendPINDigit($0) },
                                        onDelete: { viewModel.deletePINDigit() }
                                    )
                                }
                                .id("pin")
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }

                            // Error pill
                            if let error = viewModel.loginError {
                                HStack(spacing: DSSpace.sm) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(error)
                                        .font(DSFont.callout)
                                }
                                .foregroundStyle(Color.dsStatusActive)
                                .padding(.horizontal, DSSpace.lg)
                                .padding(.vertical, DSSpace.sm)
                                .background(Color.dsStatusActiveSoft)
                                .clipShape(Capsule())
                                .transition(.scale(scale: 0.9).combined(with: .opacity))
                            }
                        }
                        .animation(.spring(response: 0.3), value: viewModel.loginError != nil)
                        .padding(.horizontal, DSSpace.xl)
                        .padding(.top, DSSpace.xl)
                        .padding(.bottom, geo.safeAreaInsets.bottom + DSSpace.xl)
                        .frame(
                            minHeight: geo.size.height - (viewModel.selectedRanger == nil ? 240 : 140) + 1,
                            alignment: .top
                        )
                        .background(Color.dsBackground)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .background(Color.dsBackground.ignoresSafeArea())
        .onAppear {
            viewModel.seedDemoRangersIfNeeded(
                authManager: appEnv.authManager,
                persistence: appEnv.persistence
            )
        }
    }
}

// MARK: - Hero

private struct LoginHeroView: View {
    let width: CGFloat
    let isCompact: Bool

    private var heroHeight: CGFloat { isCompact ? 140 : 240 }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Solid gradient — no blending into the background
            LinearGradient(
                colors: [Color.dsPrimaryDeep, Color.dsPrimary],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: width, height: heroHeight)

            // Subtle concentric topo rings
            Canvas { ctx, size in
                for i in 0..<6 {
                    let r = CGFloat(i) * 40 + 20
                    let cx = size.width * 0.78
                    let cy = size.height * 0.30
                    let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                    ctx.stroke(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(0.045)),
                        lineWidth: 1.5
                    )
                }
            }
            .frame(width: width, height: heroHeight)

            // Brand lockup
            VStack(spacing: DSSpace.sm) {
                if !isCompact {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.12))
                            .frame(width: 70, height: 70)
                        Circle()
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                            .frame(width: 70, height: 70)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(.white.opacity(0.95))
                    }
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }

                VStack(spacing: 4) {
                    Text("Lama Lama Rangers")
                        .font(isCompact ? DSFont.headline : DSFont.largeTitle)
                        .foregroundStyle(.white)
                    Text("Yintjingga Aboriginal Corporation")
                        .font(DSFont.callout)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .padding(.bottom, DSSpace.xl)
        }
        .frame(height: heroHeight)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isCompact)
    }
}

// MARK: - Ranger Avatar Card

struct RangerAvatarCard: View {
    let ranger: RangerProfile
    let isSelected: Bool
    let action: () -> Void

    private var initials: String {
        let parts = (ranger.displayName ?? "R").split(separator: " ")
        return parts.prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }

    private var roleLabel: String {
        (ranger.role ?? "Ranger")
            .replacingOccurrences(of: "seniorRanger", with: "Senior Ranger")
            .replacingOccurrences(of: "ranger", with: "Ranger")
    }

    private var avatarColor: Color {
        let name = ranger.displayName ?? ""
        let palette: [Color] = [.dsAccentDeep, .dsPrimary, Color(hex: "7B5EA8"), Color(hex: "2E7A6B"), Color(hex: "C4A32E")]
        let idx = abs(name.hashValue) % palette.count
        return palette[idx]
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: DSSpace.sm) {
                ZStack {
                    Circle()
                        .fill(isSelected ? avatarColor : Color.dsSurface)
                        .frame(width: 56, height: 56)
                    Text(initials)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? .white : Color.dsInk2)
                }
                .overlay(
                    Circle().strokeBorder(
                        isSelected ? avatarColor : Color.dsDivider,
                        lineWidth: isSelected ? 2.5 : 1
                    )
                )
                .shadow(color: isSelected ? avatarColor.opacity(0.3) : .clear, radius: 6, y: 3)

                VStack(spacing: 2) {
                    Text(ranger.displayName?.components(separatedBy: " ").first ?? "Ranger")
                        .font(DSFont.callout)
                        .foregroundStyle(Color.dsInk)
                    Text(roleLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.dsInk3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpace.md)
            .background(
                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                    .fill(isSelected ? avatarColor.opacity(0.08) : Color.dsCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? avatarColor.opacity(0.45) : Color.dsDivider.opacity(0.6),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(color: isSelected ? avatarColor.opacity(0.12) : Color.dsInk.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

// MARK: - PIN Keypad

private struct PINKeypad: View {
    let onDigit: (String) -> Void
    let onDelete: () -> Void

    private let rows = [["1","2","3"], ["4","5","6"], ["7","8","9"], ["","0","⌫"]]

    var body: some View {
        VStack(spacing: DSSpace.sm) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: DSSpace.sm) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Color.clear.frame(maxWidth: .infinity).frame(height: 64)
                        } else if key == "⌫" {
                            Button { onDelete() } label: {
                                Image(systemName: "delete.left")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(Color.dsInk2)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 64)
                                    .background(Color.dsSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                            .strokeBorder(Color.dsDivider, lineWidth: 0.75)
                                    )
                            }
                            .buttonStyle(KeyTapStyle())
                        } else {
                            Button { onDigit(key) } label: {
                                Text(key)
                                    .font(.system(size: 24, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.dsInk)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 64)
                                    .background(Color.dsCard)
                                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                            .strokeBorder(Color.dsDivider, lineWidth: 0.75)
                                    )
                                    .shadow(color: Color.dsInk.opacity(0.05), radius: 2, y: 1)
                            }
                            .buttonStyle(KeyTapStyle())
                        }
                    }
                }
            }
        }
    }
}

// Subtle scale-down press effect for keypad buttons
private struct KeyTapStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Ranger Chip (kept for any remaining callers)
struct RangerChip: View {
    let ranger: RangerProfile
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(ranger.displayName ?? "Ranger")
                .font(DSFont.callout)
                .fontWeight(.semibold)
                .padding(.horizontal, DSSpace.lg)
                .padding(.vertical, DSSpace.sm)
                .background(isSelected ? Color.dsPrimary : Color.dsSurface)
                .foregroundStyle(isSelected ? .white : Color.dsInk)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
