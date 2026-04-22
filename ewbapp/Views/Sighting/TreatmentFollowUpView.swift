import SwiftUI

// MARK: - TreatmentFollowUpView

/// Form allowing a ranger to record the outcome of a follow-up survey after a
/// weed treatment — capturing % plants dead, regrowth level, optional notes and
/// an optional field photo.
struct TreatmentFollowUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnv: AppEnvironment

    let treatment: TreatmentRecord
    /// Called after a successful save so the parent can refresh its data.
    var onSave: () -> Void

    @State private var followUpDate: Date = Date()
    @State private var percentDead: Double = 50
    @State private var regrowthLevel: RegrowthLevel = .light
    @State private var notes: String = ""
    @State private var photoFilename: String? = nil
    @State private var isSaving: Bool = false

    private var formattedPercent: String {
        String(format: "%.0f%%", percentDead)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Date
                Section("Follow-Up Date") {
                    DatePicker(
                        "Date of Survey",
                        selection: $followUpDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }

                // % Plants dead
                Section {
                    VStack(alignment: .leading, spacing: DSSpace.sm) {
                        HStack {
                            Text("Plants Dead")
                                .font(DSFont.callout)
                                .foregroundStyle(Color.dsInk)
                            Spacer()
                            Text(formattedPercent)
                                .font(DSFont.callout)
                                .foregroundStyle(Color.dsPrimary)
                                .monospacedDigit()
                        }
                        Slider(value: $percentDead, in: 0...100, step: 5)
                            .tint(Color.dsPrimary)
                        HStack {
                            Text("0%")
                                .font(DSFont.badge)
                                .foregroundStyle(Color.dsInkMuted)
                            Spacer()
                            Text("100%")
                                .font(DSFont.badge)
                                .foregroundStyle(Color.dsInkMuted)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Re-Survey Result")
                } footer: {
                    Text("Estimated percentage of treated plants that are dead or dying.")
                        .font(DSFont.badge)
                }

                // Regrowth level
                Section("Regrowth Level") {
                    Picker("Regrowth Level", selection: $regrowthLevel) {
                        ForEach(RegrowthLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }

                // Notes
                Section("Notes (optional)") {
                    TextField(
                        "Additional observations, site conditions, etc.",
                        text: $notes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                // Photo
                Section("Photo (optional)") {
                    HStack {
                        Text("Follow-up photo")
                            .font(DSFont.callout)
                            .foregroundStyle(Color.dsInk)
                        Spacer()
                        if photoFilename != nil {
                            Text("1 attached")
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
                        photoFilename = "followup_\(UUID().uuidString).heif"
                    } label: {
                        HStack {
                            Image(systemName: photoFilename == nil ? "plus" : "arrow.triangle.2.circlepath")
                                .font(.system(size: 13, weight: .semibold))
                            Text(photoFilename == nil ? "Attach Photo" : "Replace Photo")
                                .font(DSFont.callout)
                        }
                        .foregroundStyle(Color.dsPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Follow-Up Assessment")
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

    // MARK: - Save

    private func save() {
        isSaving = true
        let vm = TreatmentEffectivenessViewModel(
            sighting: treatment.sighting ?? SightingLog(),
            persistence: appEnv.persistence
        )
        Task {
            await vm.saveFollowUp(
                for: treatment,
                followUpDate: followUpDate,
                percentDead: percentDead,
                regrowthLevel: regrowthLevel,
                notes: notes.isEmpty ? nil : notes,
                photoPath: photoFilename
            )
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}
