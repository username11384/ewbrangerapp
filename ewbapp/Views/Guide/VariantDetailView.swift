import SwiftUI

struct VariantDetailView: View {
    let info: LantanaVariantContent.VariantInfo
    @Environment(\.dismiss) private var dismiss

    private var isBiocontrolSeason: Bool {
        let month = Calendar.current.component(.month, from: Date())
        return month >= 11 || month <= 3
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.paper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .bottom) {
                        LinearGradient(
                            colors: [info.variant.color, Color.eucDark.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 200)

                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("LANTANA CAMARA")
                                    .font(.system(size: 11, weight: .semibold))
                                    .tracking(1.2)
                                    .foregroundColor(.white.opacity(0.75))
                                Text(info.commonName)
                                    .font(.system(size: 30, weight: .heavy))
                                    .tracking(-0.5)
                                    .foregroundColor(.white)
                            }
                            .padding(.leading, 18)
                            .padding(.bottom, 18)

                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 70, height: 70)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                Image(systemName: "leaf")
                                    .font(.system(size: 38))
                                    .foregroundColor(.white)
                            }
                            .padding(.trailing, 18)
                            .padding(.bottom, 18)
                        }
                    }

                    if info.variant == .pink && isBiocontrolSeason {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 22))
                                .foregroundColor(.ochreDeep)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pink Lantana biocontrol active · Nov – Mar")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.ochreDeep)
                                Text("Don't apply foliar spray on flowering pink plants. The leaf-sucking bug does the work — let them feed.")
                                    .font(.system(size: 12.5))
                                    .foregroundColor(.ink2)
                            }
                        }
                        .padding(12)
                        .background(Color.ochreSoft)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ochre, lineWidth: 1))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("HOW TO SPOT IT")
                                .font(.system(size: 13, weight: .bold))
                                .tracking(1.0)
                                .foregroundColor(.ink3)

                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(featureBullets, id: \.self) { feature in
                                    HStack(alignment: .top, spacing: 10) {
                                        Circle()
                                            .fill(info.variant.color)
                                            .frame(width: 6, height: 6)
                                            .padding(.top, 5)
                                        Text(feature)
                                            .font(.system(size: 14))
                                            .foregroundColor(.ink)
                                            .lineSpacing(1.4)
                                    }
                                }
                            }
                            .dsCard()
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("CONTROL METHODS")
                                .font(.system(size: 13, weight: .bold))
                                .tracking(1.0)
                                .foregroundColor(.ink3)

                            ForEach(Array(info.controlMethods.enumerated()), id: \.element) { index, method in
                                ControlMethodCard(method: method, index: index, accentColor: info.variant.color)
                            }
                        }

                        if let seasonal = info.seasonalNotes {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("SEASONAL NOTE")
                                    .font(.system(size: 13, weight: .bold))
                                    .tracking(1.0)
                                    .foregroundColor(.ink3)

                                Text(seasonal)
                                    .font(.system(size: 14))
                                    .foregroundColor(.ink)
                                    .lineSpacing(1.4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .dsCard()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, info.variant == .pink && isBiocontrolSeason ? 0 : 20)
                    .padding(.bottom, 32)
                }
            }

            HStack {
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 38, height: 38)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.ink)
                    }
                }
                .padding(.leading, 16)
                .padding(.top, 54)
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }

    private var featureBullets: [String] {
        info.distinguishingFeatures
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { $0.hasSuffix(".") ? $0 : $0 + "." }
    }
}

private struct ControlMethodCard: View {
    let method: TreatmentMethod
    let index: Int
    let accentColor: Color

    private var steps: [String] {
        method.instructions
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .prefix(2)
            .map { $0.hasSuffix(".") ? $0 : $0 + "." }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.eucSoft)
                        .frame(width: 22, height: 22)
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.euc)
                }
                Text(method.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.ink)
            }

            ForEach(steps, id: \.self) { step in
                Text(step)
                    .font(.system(size: 13.5))
                    .foregroundColor(.ink)
                    .lineSpacing(1.3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }
}
