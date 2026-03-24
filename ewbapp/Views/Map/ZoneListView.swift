import SwiftUI

struct ZoneListView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @State private var zones: [InfestationZone] = []
    @State private var editingZone: InfestationZone?
    @State private var showAddZone = false

    var body: some View {
        List {
            ForEach(zones, id: \.id) { zone in
                Button {
                    editingZone = zone
                } label: {
                    HStack(spacing: 12) {
                        VariantColourDot(variant: LantanaVariant(rawValue: zone.dominantVariant ?? "") ?? .unknown, size: 14)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(zone.name ?? "Unnamed Zone")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(statusLabel(zone.status))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { offsets in
                let toDelete = offsets.map { zones[$0] }
                toDelete.forEach { deleteZone($0) }
            }
        }
        .navigationTitle("Zones")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddZone = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(item: $editingZone) { zone in
            EditZoneView(zone: zone) { load() }
        }
        .sheet(isPresented: $showAddZone, onDismiss: load) {
            AddZoneView()
        }
        .onAppear { load() }
    }

    private func load() {
        let repo = ZoneRepository(persistence: appEnv.persistence)
        zones = (try? repo.fetchAllZones()) ?? []
    }

    private func deleteZone(_ zone: InfestationZone) {
        let repo = ZoneRepository(persistence: appEnv.persistence)
        Task {
            try? await repo.deleteZone(zone)
            load()
        }
    }

    private func statusLabel(_ status: String?) -> String {
        switch status {
        case "underTreatment": return "Under Treatment"
        case "cleared": return "Cleared"
        default: return "Active"
        }
    }
}

struct EditZoneView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnv: AppEnvironment

    let zone: InfestationZone
    var onSave: () -> Void

    @State private var zoneName: String
    @State private var selectedVariant: LantanaVariant
    @State private var selectedStatus: String
    @State private var isSaving = false

    init(zone: InfestationZone, onSave: @escaping () -> Void) {
        self.zone = zone
        self.onSave = onSave
        _zoneName = State(initialValue: zone.name ?? "")
        _selectedVariant = State(initialValue: LantanaVariant(rawValue: zone.dominantVariant ?? "") ?? .unknown)
        _selectedStatus = State(initialValue: zone.status ?? "active")
    }

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
            }
            .navigationTitle("Edit Zone")
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
            try? await repo.updateZone(
                zone,
                name: zoneName.isEmpty ? nil : zoneName,
                dominantVariant: selectedVariant,
                status: selectedStatus
            )
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}
