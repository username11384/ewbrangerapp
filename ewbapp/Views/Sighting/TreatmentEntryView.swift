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
    @State private var afterPhotoFilenames: [String] = []
    @State private var showHerbicideChecker = false

    /// Species display name used to pre-filter the herbicide checker
    private var speciesDisplayName: String {
        InvasiveSpecies.from(legacyVariant: sighting.variant ?? "").displayName
    }

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
                    TextField("e.g. Garlon 600, Access, Tordon 75-D (optional)", text: $herbicideProduct)
                }

                Section("Outcome Notes") {
                    TextField("Observations, coverage, etc. (optional)", text: $outcomeNotes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("After Photos (optional)") {
                    HStack {
                        Text("After photos")
                            .font(DSFont.callout)
                            .foregroundStyle(Color.dsInk)
                        Spacer()
                        if afterPhotoFilenames.count > 0 {
                            Text("\(afterPhotoFilenames.count) attached")
                                .font(DSFont.badge)
                                .foregroundStyle(Color.dsPrimary)
                                .padding(.horizontal, DSSpace.sm)
                                .padding(.vertical, 3)
                                .background(Color.dsPrimarySoft)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)

                    Button {
                        afterPhotoFilenames.append("after_\(UUID().uuidString).heif")
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Attach After Photo")
                                .font(DSFont.callout)
                        }
                        .foregroundStyle(Color.dsPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }
                }

                Section("Herbicide Reference") {
                    Button {
                        showHerbicideChecker = true
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.shield")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.dsPrimary)
                                .frame(width: 22)
                            Text("Check herbicide compatibility")
                                .font(DSFont.callout)
                                .foregroundStyle(Color.dsPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.dsInkMuted)
                        }
                        .padding(.vertical, 2)
                    }
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
            .sheet(isPresented: $showHerbicideChecker) {
                NavigationStack {
                    HerbicideCheckerView(preFilteredSpecies: speciesDisplayName)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showHerbicideChecker = false }
                                    .foregroundStyle(Color.dsPrimary)
                            }
                        }
                }
            }
        }
    }

    private func save() {
        guard let rangerID = appEnv.authManager.currentRangerID else { return }
        isSaving = true
        let repo = TreatmentRepository(persistence: appEnv.persistence)
        Task {
            var finalNotes = outcomeNotes
            if !afterPhotoFilenames.isEmpty {
                let prefix = "📷 After: \(afterPhotoFilenames.count) photo(s). "
                finalNotes = prefix + outcomeNotes
            }
            let treatment = try? await repo.addTreatment(
                to: sighting,
                method: selectedMethod,
                herbicideProduct: herbicideProduct.isEmpty ? nil : herbicideProduct,
                outcomeNotes: finalNotes.isEmpty ? nil : finalNotes,
                followUpDate: hasFollowUp ? followUpDate : nil,
                rangerID: rangerID
            )
            if let treatment {
                let taskRepo = TaskRepository(persistence: appEnv.persistence)
                try? await taskRepo.createFollowUpTask(for: treatment, rangerID: rangerID)
            }
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}
