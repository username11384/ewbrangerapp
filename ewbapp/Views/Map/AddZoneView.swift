import SwiftUI

struct AddZoneView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnv: AppEnvironment

    @State private var zoneName = ""
    @State private var selectedSpecies: InvasiveSpecies = .unknown
    @State private var selectedStatus = "active"
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Zone Details") {
                    TextField("Zone Name (optional)", text: $zoneName)

                    Picker("Dominant Species", selection: $selectedSpecies) {
                        ForEach(InvasiveSpecies.allCases, id: \.self) { s in
                            HStack {
                                SpeciesIndicator(species: s, size: 10)
                                Text(s.displayName)
                            }
                            .tag(s)
                        }
                    }

                    Picker("Status", selection: $selectedStatus) {
                        Text("Active").tag("active")
                        Text("Under Treatment").tag("underTreatment")
                        Text("Cleared").tag("cleared")
                    }
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
            _ = try? await repo.createZone(name: name, dominantSpecies: selectedSpecies)
            await MainActor.run { dismiss() }
        }
    }
}
