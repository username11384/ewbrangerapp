import SwiftUI

struct ControlProtocolView: View {
    @State private var selectedVariant: LantanaVariant?
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
                VStack(spacing: 20) {
                    // Seasonal alerts
                    let alerts = SeasonalAlert.activeAlerts(recentRain: recentRain)
                    ForEach(alerts.indices, id: \.self) { i in
                        SeasonalAlertBanner(alert: alerts[i])
                    }

                    // Step 1 — Variant
                    QuestionCard(number: 1, question: "What variant is it?") {
                        VariantPickerView(selectedVariant: $selectedVariant)
                    }

                    // Step 2 — Size (only if variant selected)
                    if selectedVariant != nil {
                        QuestionCard(number: 2, question: "How large is the infestation?") {
                            SizePickerView(selectedSize: Binding(
                                get: { selectedSize ?? .small },
                                set: { selectedSize = $0 }
                            ))
                        }
                    }

                    // Step 3 — Biocontrol (only for pink variant)
                    if selectedVariant?.hasBiocontrolConcern == true {
                        QuestionCard(number: 3, question: "Are biocontrol insects visible?") {
                            HStack(spacing: 8) {
                                ForEach(BiocontrolAnswer.allCases, id: \.self) { answer in
                                    Button(answer.rawValue) {
                                        biocontrolVisible = answer
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(biocontrolVisible == answer ? Color.orange : Color(.systemGray5))
                                    .foregroundColor(biocontrolVisible == answer ? .white : .primary)
                                    .cornerRadius(10)
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Result card
                    if let variant = selectedVariant, let size = selectedSize {
                        ResultCard(variant: variant, size: size, biocontrol: biocontrolVisible)
                    }
                }
                .padding()
            }
            .navigationTitle("Control Protocol")
        }
    }
}

struct QuestionCard<Content: View>: View {
    let number: Int
    let question: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Step \(number)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(6)
                Text(question)
                    .font(.headline)
            }
            content
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ResultCard: View {
    let variant: LantanaVariant
    let size: InfestationSize
    let biocontrol: ControlProtocolView.BiocontrolAnswer?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recommendation", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundColor(.green)

            if biocontrol == .yes {
                Text("Biocontrol insects detected — do NOT spray. Allow insects to feed. Monitor in 3–4 weeks.")
                    .font(.body)
                    .foregroundColor(.orange)
            } else {
                ForEach(variant.controlMethods, id: \.self) { method in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(method.displayName)
                            .font(.subheadline.bold())
                        Text(method.instructions)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
