import SwiftUI

struct TreatmentEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnv: AppEnvironment

    let sighting: SightingLog
    var onSave: () -> Void

    @State private var selectedMethod: TreatmentMethod = .foliarSpray
    @State private var herbicideProduct = ""
    @State private var outcomeNotes = ""
    @State private var hasFollowUp = false
    @State private var followUpDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Treatment Method") {
                    Picker("Method", selection: $selectedMethod) {
                        ForEach(TreatmentMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Herbicide Product") {
                    TextField("e.g. Garlon 600, Access (optional)", text: $herbicideProduct)
                }

                Section("Outcome Notes") {
                    TextField("Observations, coverage, etc. (optional)", text: $outcomeNotes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Follow-up") {
                    Toggle("Schedule regrowth check", isOn: $hasFollowUp)
                    if hasFollowUp {
                        DatePicker("Follow-up Date", selection: $followUpDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Add Treatment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(isSaving)
                }
            }
        }
    }

    private func save() {
        guard let rangerID = appEnv.authManager.currentRangerID else { return }
        isSaving = true
        let repo = TreatmentRepository(persistence: appEnv.persistence)
        Task {
            _ = try? await repo.addTreatment(
                to: sighting,
                method: selectedMethod,
                herbicideProduct: herbicideProduct.isEmpty ? nil : herbicideProduct,
                outcomeNotes: outcomeNotes.isEmpty ? nil : outcomeNotes,
                followUpDate: hasFollowUp ? followUpDate : nil,
                rangerID: rangerID
            )
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}
