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
                        ZStack(alignment: .bottom) {
                            // Background photo or gradient fallback
                            if let img = UIImage(named: "login_hero") {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geo.size.width,
                                           height: viewModel.selectedRanger == nil ? 300 : 180)
                                    .clipped()
                                    .overlay(
                                        LinearGradient(
                                            colors: [Color.dsPrimaryDeep.opacity(0.7), Color.dsPrimaryDeep.opacity(0.2)],
                                            startPoint: .top, endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        LinearGradient(
                                            colors: [.clear, Color.dsBackground],
                                            startPoint: .center, endPoint: .bottom
                                        )
                                    )
                            } else {
                                LinearGradient(
                                    colors: [Color.dsPrimaryDeep, Color.dsPrimary],
                                    startPoint: .top, endPoint: .bottom
                                )
                                .frame(height: viewModel.selectedRanger == nil ? 300 : 180)
                            }

                            // Logo + title
                            VStack(spacing: 6) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 38, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.95))
                                    .shadow(color: .black.opacity(0.3), radius: 4)
                                Text("Lama Lama Rangers")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.4), radius: 4)
                                Text("Yintjingga Aboriginal Corporation")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .shadow(color: .black.opacity(0.3), radius: 2)
                            }
                            .padding(.bottom, 28)
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.8),
                                   value: viewModel.selectedRanger == nil)

                        // ── Card ──────────────────────────────────────────
                        VStack(spacing: DSSpace.xl) {
                            // Ranger selection
                            VStack(alignment: .leading, spacing: DSSpace.md) {
                                Text("Who are you?")
                                    .font(DSFont.headline)
                                    .foregroundStyle(Color.dsInk)

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
                                    VStack(spacing: DSSpace.sm) {
                                        Text("Enter PIN")
                                            .font(DSFont.callout)
                                            .foregroundStyle(Color.dsInk3)
                                        HStack(spacing: 18) {
                                            ForEach(0..<4, id: \.self) { i in
                                                Circle()
                                                    .fill(i < viewModel.enteredPIN.count
                                                          ? Color.dsPrimary
                                                          : Color.dsSurface)
                                                    .frame(width: 14, height: 14)
                                                    .overlay(
                                                        Circle().strokeBorder(
                                                            i < viewModel.enteredPIN.count
                                                            ? Color.clear
                                                            : Color.dsDivider,
                                                            lineWidth: 1.5
                                                        )
                                                    )
                                                    .animation(.spring(response: 0.2),
                                                               value: viewModel.enteredPIN.count)
                                            }
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

                            if let error = viewModel.loginError {
                                Text(error)
                                    .font(DSFont.callout)
                                    .foregroundStyle(Color.dsStatusActive)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, DSSpace.xl)
                        .padding(.top, DSSpace.xl)
                        .padding(.bottom, geo.safeAreaInsets.bottom + DSSpace.xl)
                        .frame(minHeight: geo.size.height
                               - (viewModel.selectedRanger == nil ? 300 : 180)
                               + 1, alignment: .top)
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
                .shadow(color: isSelected ? avatarColor.opacity(0.25) : .clear, radius: 4, y: 2)

                VStack(spacing: 2) {
                    Text(ranger.displayName?.components(separatedBy: " ").first ?? "Ranger")
                        .font(DSFont.callout)
                        .foregroundStyle(isSelected ? avatarColor : Color.dsInk)
                    Text(roleLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.dsInk3)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpace.md)
            .background(
                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                    .fill(isSelected ? avatarColor.opacity(0.07) : Color.dsCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? avatarColor.opacity(0.4) : Color.dsDivider.opacity(0.6),
                        lineWidth: 1
                    )
            )
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
                            Color.clear.frame(maxWidth: .infinity).frame(height: 60)
                        } else if key == "⌫" {
                            Button { onDelete() } label: {
                                Image(systemName: "delete.left")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(maxWidth: .infinity).frame(height: 60)
                                    .background(Color.dsSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                            .strokeBorder(Color.dsDivider, lineWidth: 0.75)
                                    )
                            }
                            .foregroundStyle(Color.dsInk2)
                            .buttonStyle(.plain)
                        } else {
                            Button { onDigit(key) } label: {
                                Text(key)
                                    .font(.system(size: 22, weight: .medium, design: .rounded))
                                    .frame(maxWidth: .infinity).frame(height: 60)
                                    .background(Color.dsCard)
                                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                            .strokeBorder(Color.dsDivider, lineWidth: 0.75)
                                    )
                            }
                            .foregroundStyle(Color.dsInk)
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
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
