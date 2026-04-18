import SwiftUI

private enum LoginStep { case pick, pin }

struct LoginView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: LoginViewModel
    @State private var step: LoginStep = .pick
    @State private var shakeOffset: CGFloat = 0

    init() {
        _viewModel = StateObject(wrappedValue: LoginViewModel(
            authManager: AppEnvironment.shared.authManager,
            persistence: AppEnvironment.shared.persistence
        ))
    }

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    CapeYorkHeader()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CAPE YORK · PORT STEWART")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(1.4)
                            .foregroundColor(.bark)
                        Text("Lama Lama")
                            .font(.system(size: 30, weight: .heavy))
                            .tracking(-0.5)
                            .foregroundColor(.euc)
                        Text("Rangers")
                            .font(.system(size: 30, weight: .heavy))
                            .tracking(-0.5)
                            .foregroundColor(.ochre)
                            .padding(.bottom, 20)

                        if step == .pick {
                            RangerPickStep(viewModel: viewModel) { ranger in
                                viewModel.selectRanger(ranger)
                                step = .pin
                            }
                        } else {
                            PINStep(
                                viewModel: viewModel,
                                shakeOffset: shakeOffset,
                                onBack: {
                                    step = .pick
                                    viewModel.enteredPIN = ""
                                    viewModel.loginError = nil
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .onChange(of: viewModel.loginError) { _, error in
            guard error != nil else { return }
            withAnimation(.interpolatingSpring(stiffness: 500, damping: 10)) {
                shakeOffset = 8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation { shakeOffset = 0 }
            }
        }
        .onAppear {
            viewModel.seedDemoRangersIfNeeded(authManager: appEnv.authManager, persistence: appEnv.persistence)
        }
    }
}

// MARK: - Cape York Header

private struct CapeYorkHeader: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(colors: [Color(hex: "E6D8B7"), Color(hex: "C89F6B")]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 0, y: h)
            ))

            let sunX = w * 0.80
            let sunY = h * 0.35
            ctx.opacity = 0.8
            var outerCircle = Path()
            outerCircle.addEllipse(in: CGRect(x: sunX - 26, y: sunY - 26, width: 52, height: 52))
            ctx.fill(outerCircle, with: .color(Color(hex: "F3DEC5").opacity(0.8)))

            ctx.opacity = 1.0
            var innerCircle = Path()
            innerCircle.addEllipse(in: CGRect(x: sunX - 18, y: sunY - 18, width: 36, height: 36))
            ctx.fill(innerCircle, with: .color(Color(hex: "E8B07A")))

            for i in 0..<7 {
                let baseY = h * 0.43 + CGFloat(i) * 11
                let amplitude: CGFloat = 6 + CGFloat(i) * 1.0
                var wavePath = Path()
                wavePath.move(to: CGPoint(x: 0, y: baseY))
                let steps = 20
                for s in 0...steps {
                    let x = w * CGFloat(s) / CGFloat(steps)
                    let phase = CGFloat(s) / CGFloat(steps) * .pi * 4
                    let y = baseY + sin(phase + CGFloat(i) * 0.7) * amplitude
                    wavePath.addLine(to: CGPoint(x: x, y: y))
                }
                let opacity = 0.15 + Double(i) * 0.08
                ctx.stroke(wavePath, with: .color(Color.euc.opacity(opacity)), lineWidth: 1.1)
            }

            var ridge1 = Path()
            ridge1.move(to: CGPoint(x: 0, y: h))
            ridge1.addLine(to: CGPoint(x: 0, y: h * 0.72))
            ridge1.addCurve(
                to: CGPoint(x: w * 0.25, y: h * 0.60),
                control1: CGPoint(x: w * 0.07, y: h * 0.66),
                control2: CGPoint(x: w * 0.13, y: h * 0.58)
            )
            ridge1.addCurve(
                to: CGPoint(x: w * 0.50, y: h * 0.68),
                control1: CGPoint(x: w * 0.35, y: h * 0.62),
                control2: CGPoint(x: w * 0.42, y: h * 0.72)
            )
            ridge1.addCurve(
                to: CGPoint(x: w * 0.75, y: h * 0.56),
                control1: CGPoint(x: w * 0.60, y: h * 0.64),
                control2: CGPoint(x: w * 0.68, y: h * 0.54)
            )
            ridge1.addCurve(
                to: CGPoint(x: w, y: h * 0.63),
                control1: CGPoint(x: w * 0.84, y: h * 0.58),
                control2: CGPoint(x: w * 0.92, y: h * 0.66)
            )
            ridge1.addLine(to: CGPoint(x: w, y: h))
            ridge1.closeSubpath()
            ctx.fill(ridge1, with: .color(Color.euc.opacity(0.85)))

            var ridge2 = Path()
            ridge2.move(to: CGPoint(x: 0, y: h))
            ridge2.addLine(to: CGPoint(x: 0, y: h * 0.82))
            ridge2.addCurve(
                to: CGPoint(x: w * 0.20, y: h * 0.74),
                control1: CGPoint(x: w * 0.06, y: h * 0.80),
                control2: CGPoint(x: w * 0.13, y: h * 0.72)
            )
            ridge2.addCurve(
                to: CGPoint(x: w * 0.45, y: h * 0.80),
                control1: CGPoint(x: w * 0.30, y: h * 0.77),
                control2: CGPoint(x: w * 0.38, y: h * 0.83)
            )
            ridge2.addCurve(
                to: CGPoint(x: w * 0.70, y: h * 0.70),
                control1: CGPoint(x: w * 0.55, y: h * 0.76),
                control2: CGPoint(x: w * 0.62, y: h * 0.68)
            )
            ridge2.addCurve(
                to: CGPoint(x: w, y: h * 0.76),
                control1: CGPoint(x: w * 0.82, y: h * 0.72),
                control2: CGPoint(x: w * 0.92, y: h * 0.78)
            )
            ridge2.addLine(to: CGPoint(x: w, y: h))
            ridge2.closeSubpath()
            ctx.fill(ridge2, with: .color(Color.eucDark))
        }
        .frame(height: 160)
        .clipped()
    }
}

// MARK: - Ranger Pick Step

private struct RangerPickStep: View {
    @ObservedObject var viewModel: LoginViewModel
    let onSelect: (RangerProfile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Good to see you. Who's signing on today?")
                .font(.system(size: 14))
                .foregroundColor(.ink3)

            VStack(spacing: 10) {
                ForEach(viewModel.rangers, id: \.id) { ranger in
                    RangerCardButton(ranger: ranger) { onSelect(ranger) }
                }
            }
        }
    }
}

private struct RangerCardButton: View {
    let ranger: RangerProfile
    let action: () -> Void

    private var initials: String {
        let words = (ranger.displayName ?? "").split(separator: " ")
        return words.prefix(2).compactMap { $0.first.map { String($0) } }.joined().uppercased()
    }

    private var toneColor: Color {
        let palette: [Color] = [.ochreDeep, .euc, .ochre, .bark, .statusCleared]
        let idx = abs(ranger.displayName?.hashValue ?? 0) % palette.count
        return palette[idx]
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(toneColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(initials)
                            .font(.system(size: 15, weight: .bold, design: .default))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(ranger.displayName ?? "Ranger")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.ink)
                    Text(ranger.role ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(.ink3)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.ink3)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 56)
            .background(Color.card)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PIN Step

private struct PINStep: View {
    @ObservedObject var viewModel: LoginViewModel
    let shakeOffset: CGFloat
    let onBack: () -> Void

    private var initials: String {
        let words = (viewModel.selectedRanger?.displayName ?? "").split(separator: " ")
        return words.prefix(2).compactMap { $0.first.map { String($0) } }.joined().uppercased()
    }

    private var toneColor: Color {
        let palette: [Color] = [.ochreDeep, .euc, .ochre, .bark, .statusCleared]
        let idx = abs(viewModel.selectedRanger?.displayName?.hashValue ?? 0) % palette.count
        return palette[idx]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button(action: onBack) {
                Text("< Change ranger")
                    .font(.system(size: 14))
                    .foregroundColor(.euc)
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                Circle()
                    .fill(toneColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(initials)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedRanger?.displayName ?? "")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.ink)
                    Text("Enter your 4-digit PIN")
                        .font(.system(size: 12))
                        .foregroundColor(.ink3)
                }
            }

            HStack(spacing: 14) {
                ForEach(0..<4, id: \.self) { i in
                    if i < viewModel.enteredPIN.count {
                        Circle()
                            .fill(Color.euc)
                            .frame(width: 18, height: 18)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 18, height: 18)
                            .overlay(Circle().stroke(Color.lineBase.opacity(0.22), lineWidth: 1.5))
                    }
                }
            }
            .offset(x: shakeOffset)
            .frame(maxWidth: .infinity, alignment: .center)

            LoginKeypad(
                onDigit: { viewModel.appendPINDigit($0) },
                onDelete: { viewModel.deletePINDigit() }
            )
        }
    }
}

// MARK: - Keypad

private struct LoginKeypad: View {
    let onDigit: (String) -> Void
    let onDelete: () -> Void

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", "⌫"]
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: 64)
                        } else if key == "⌫" {
                            Button(action: onDelete) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.ink2)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 64)
                                    .background(Color.card)
                                    .cornerRadius(18)
                                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(action: { onDigit(key) }) {
                                Text(key)
                                    .font(.system(size: 28, weight: .medium, design: .rounded))
                                    .foregroundColor(.ink)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 64)
                                    .background(Color.card)
                                    .cornerRadius(18)
                                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
