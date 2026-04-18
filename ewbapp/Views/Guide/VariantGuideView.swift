import SwiftUI

struct VariantGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private var isBiocontrolSeason: Bool {
        let month = Calendar.current.component(.month, from: Date())
        return month >= 11 || month <= 3
    }

    let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Lantana guide")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.ink)
                            Text("Six variants on country · tap one to learn identifying marks")
                                .font(.system(size: 13))
                                .foregroundColor(.ink3)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 54)
                        .padding(.bottom, 20)

                        if isBiocontrolSeason {
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
                            .padding(.bottom, 16)
                        }

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(LantanaVariantContent.all, id: \.variant) { info in
                                NavigationLink(destination: VariantDetailView(info: info)) {
                                    VariantCard(info: info, isBiocontrolSeason: isBiocontrolSeason)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private struct VariantCard: View {
    let info: LantanaVariantContent.VariantInfo
    let isBiocontrolSeason: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(
                    colors: [info.variant.color, info.variant.color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 72)

                Image(systemName: "leaf")
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(10)

                if info.variant == .pink && isBiocontrolSeason {
                    Text("Biocontrol")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 7)
                        .background(Color.ochre)
                        .clipShape(Capsule())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(info.commonName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Lantana camara")
                    .font(.system(size: 11))
                    .foregroundColor(.ink3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
        }
        .background(Color.card)
        .cornerRadius(16)
        .clipped()
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.lineBase.opacity(0.10), lineWidth: 1))
    }
}
