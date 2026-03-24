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
                            if let img = UIImage(named: "demo_lantana_2") {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geo.size.width,
                                           height: viewModel.selectedRanger == nil ? 300 : 180)
                                    .clipped()
                                    .overlay(
                                        LinearGradient(
                                            colors: [.black.opacity(0.55), .black.opacity(0.15)],
                                            startPoint: .top, endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        LinearGradient(
                                            colors: [.clear, Color(.systemBackground)],
                                            startPoint: .center, endPoint: .bottom
                                        )
                                    )
                            } else {
                                LinearGradient(
                                    colors: [Color(red: 0.08, green: 0.24, blue: 0.14),
                                             Color(red: 0.13, green: 0.38, blue: 0.22)],
                                    startPoint: .top, endPoint: .bottom
                                )
                                .frame(height: viewModel.selectedRanger == nil ? 300 : 180)
                            }

                            // Logo + title
                            VStack(spacing: 6) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.95))
                                    .shadow(color: .black.opacity(0.4), radius: 4)
                                Text("Lama Lama Rangers")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 4)
                                Text("Lantana Monitoring & Control")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.75))
                                    .shadow(color: .black.opacity(0.4), radius: 2)
                            }
                            .padding(.bottom, 28)
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.8),
                                   value: viewModel.selectedRanger == nil)

                        // ── Card ──────────────────────────────────────────
                        VStack(spacing: 28) {
                            // Ranger selection
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Who are you?")
                                    .font(.system(size: 17, weight: .semibold))

                                HStack(spacing: 12) {
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

                            // PIN — appears and page scrolls to show it
                            if viewModel.selectedRanger != nil {
                                VStack(spacing: 20) {
                                    VStack(spacing: 10) {
                                        Text("Enter PIN")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.secondary)
                                        HStack(spacing: 18) {
                                            ForEach(0..<4, id: \.self) { i in
                                                Circle()
                                                    .fill(i < viewModel.enteredPIN.count
                                                          ? Color(red: 0.13, green: 0.45, blue: 0.25)
                                                          : Color(.systemGray4))
                                                    .frame(width: 14, height: 14)
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
                                    .font(.callout)
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 24)
                        .frame(minHeight: geo.size.height
                               - (viewModel.selectedRanger == nil ? 300 : 180)
                               + 1, alignment: .top)
                        .background(Color(.systemBackground))
                    }
                }
                .ignoresSafeArea(edges: .top)
                .overlay(alignment: .bottom) {
                    Text("31265 Communications for IT Professionals  ·  EWB Challenge 2026")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .padding(.bottom, geo.safeAreaInsets.bottom + 4)
                        .allowsHitTesting(false)
                }
            }
        }
        .onAppear {
            viewModel.seedDemoRangersIfNeeded(
                authManager: appEnv.authManager,
                persistence: appEnv.persistence
            )
        }
    }
}

// MARK: - Ranger avatar card

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

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected
                              ? Color(red: 0.10, green: 0.36, blue: 0.20)
                              : Color(.systemGray5))
                        .frame(width: 56, height: 56)
                    Text(initials)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? .white : .primary)
                }
                .overlay(
                    Circle().strokeBorder(
                        isSelected ? Color(red: 0.18, green: 0.55, blue: 0.32) : Color.clear,
                        lineWidth: 2.5
                    )
                )

                VStack(spacing: 2) {
                    Text(ranger.displayName?.components(separatedBy: " ").first ?? "Ranger")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(roleLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected
                          ? Color(red: 0.10, green: 0.36, blue: 0.20).opacity(0.08)
                          : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? Color(red: 0.18, green: 0.55, blue: 0.32).opacity(0.5)
                            : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

// MARK: - PIN keypad

private struct PINKeypad: View {
    let onDigit: (String) -> Void
    let onDelete: () -> Void

    private let rows = [["1","2","3"], ["4","5","6"], ["7","8","9"], ["","0","⌫"]]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Color.clear.frame(maxWidth: .infinity).frame(height: 64)
                        } else if key == "⌫" {
                            Button { onDelete() } label: {
                                Image(systemName: "delete.left")
                                    .font(.system(size: 20, weight: .medium))
                                    .frame(maxWidth: .infinity).frame(height: 64)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(14)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button { onDigit(key) } label: {
                                Text(key)
                                    .font(.system(size: 24, weight: .medium, design: .rounded))
                                    .frame(maxWidth: .infinity).frame(height: 64)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(14)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

// Kept for any other call sites
struct RangerChip: View {
    let ranger: RangerProfile
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(ranger.displayName ?? "Ranger")
                .font(.callout.bold())
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(isSelected ? Color.green : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}
