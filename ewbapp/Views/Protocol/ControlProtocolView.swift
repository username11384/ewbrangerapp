import SwiftUI

struct ControlProtocolView: View {
    @State private var selectedSpecies: InvasiveSpecies?
    @State private var selectedSize: InfestationSize?
    @State private var biocontrolVisible: BiocontrolAnswer?
    private let recentRain = UserDefaults.standard.bool(forKey: SeasonalAlertConfig.recentRainKey)

    enum BiocontrolAnswer: String, CaseIterable {
        case yes = "Yes"
        case no = "No"
        case unsure = "Unsure"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DSSpace.lg) {
                    // Seasonal alerts
                    let alerts = SeasonalAlert.activeAlerts(recentRain: recentRain)
                    ForEach(alerts.indices, id: \.self) { i in
                        SeasonalAlertBanner(alert: alerts[i])
                    }

                    // Step 1 — Species
                    QuestionCard(number: 1, question: "What species is it?") {
                        SpeciesPickerView(selectedSpecies: $selectedSpecies)
                    }

                    // Step 2 — Size (only if species selected)
                    if selectedSpecies != nil {
                        QuestionCard(number: 2, question: "How large is the infestation?") {
                            SizePickerView(selectedSize: Binding(
                                get: { selectedSize ?? .small },
                                set: { selectedSize = $0 }
                            ))
                        }
                    }

                    // Step 3 — Biocontrol (only for Lantana)
                    if selectedSpecies?.hasBiocontrolConcern == true {
                        QuestionCard(number: 3, question: "Are biocontrol insects visible?") {
                            HStack(spacing: DSSpace.sm) {
                                ForEach(BiocontrolAnswer.allCases, id: \.self) { answer in
                                    Button(answer.rawValue) {
                                        biocontrolVisible = answer
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(biocontrolVisible == answer ? Color.dsAccent : Color.dsSurface)
                                    .foregroundStyle(biocontrolVisible == answer ? Color.white : Color.dsInk2)
                                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Result card
                    if let species = selectedSpecies, let size = selectedSize {
                        ResultCard(species: species, size: size, biocontrol: biocontrolVisible)
                    }
                }
                .padding(DSSpace.lg)
            }
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationTitle("Control Protocol")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct QuestionCard<Content: View>: View {
    let number: Int
    let question: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpace.md) {
            HStack(spacing: DSSpace.sm) {
                Text("\(number)")
                    .font(DSFont.badge)
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.dsPrimary)
                    .clipShape(Circle())
                Text(question)
                    .font(DSFont.headline)
                    .foregroundStyle(Color.dsInk)
            }
            content
        }
        .dsCard()
    }
}

struct ResultCard: View {
    let species: InvasiveSpecies
    let size: InfestationSize
    let biocontrol: ControlProtocolView.BiocontrolAnswer?

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpace.md) {
            HStack(spacing: DSSpace.sm) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color.dsPrimary)
                Text("Recommendation")
                    .font(DSFont.headline)
                    .foregroundStyle(Color.dsInk)
            }

            if biocontrol == .yes {
                HStack(alignment: .top, spacing: DSSpace.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.dsStatusTreat)
                    Text("Biocontrol insects detected — do NOT spray. Allow insects to feed and monitor in 3–4 weeks.")
                        .font(DSFont.body)
                        .foregroundStyle(Color.dsInk2)
                }
                .padding(DSSpace.md)
                .background(Color.dsStatusTreatSoft)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
            } else {
                VStack(spacing: DSSpace.sm) {
                    ForEach(species.controlMethods, id: \.self) { method in
                        HStack(alignment: .top, spacing: DSSpace.md) {
                            Image(systemName: method.systemIconName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.dsPrimary)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(method.displayName)
                                    .font(DSFont.callout)
                                    .foregroundStyle(Color.dsInk)
                                Text(method.instructions)
                                    .font(DSFont.caption)
                                    .foregroundStyle(Color.dsInk2)
                            }
                            Spacer()
                        }
                        .padding(DSSpace.md)
                        .background(Color.dsPrimarySoft)
                        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                    }
                }
            }
        }
        .dsCard()
    }
}
