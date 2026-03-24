import SwiftUI

struct AddZoneView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnv: AppEnvironment

    @State private var zoneName = ""
    @State private var selectedVariant: LantanaVariant = .unknown
    @State private var selectedStatus = "active"
    @State private var isSaving = false

    private let statuses = ["active", "underTreatment", "cleared"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Zone Details") {
                    TextField("Zone Name (optional)", text: $zoneName)

                    Picker("Dominant Variant", selection: $selectedVariant) {
                        ForEach(LantanaVariant.allCases, id: \.self) { v in
                            HStack {
                                VariantColourDot(variant: v, size: 10)
                                Text(v.displayName)
                            }
                            .tag(v)
                        }
                    }

                    Picker("Status", selection: $selectedStatus) {
                        Text("Active").tag("active")
                        Text("Under Treatment").tag("underTreatment")
                        Text("Cleared").tag("cleared")
                    }
                }

                Section {
                    Text("Polygon drawing is coming in V2. For now, zones are tracked by name and status — you can link sightings to them later.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Zone")
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
        isSaving = true
        let repo = ZoneRepository(persistence: appEnv.persistence)
        Task {
            let name = zoneName.isEmpty ? nil : zoneName
            _ = try? await repo.createZone(name: name, dominantVariant: selectedVariant)
            await MainActor.run { dismiss() }
        }
    }
}
