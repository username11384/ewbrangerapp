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
                    HStack(spacing: DSSpace.md) {
                        SpeciesIndicator(
                            species: InvasiveSpecies.from(legacyVariant: zone.dominantVariant ?? ""),
                            size: 14,
                            showIcon: true
                        )
                        VStack(alignment: .leading, spacing: 3) {
                            Text(zone.name ?? "Unnamed Zone")
                                .font(DSFont.subhead)
                                .foregroundStyle(Color.dsInk)
                            HStack(spacing: 6) {
                                Text(InvasiveSpecies.from(legacyVariant: zone.dominantVariant ?? "").displayName)
                                    .font(DSFont.caption)
                                    .foregroundStyle(Color.dsInk3)
                                Text("·")
                                    .font(DSFont.caption)
                                    .foregroundStyle(Color.dsInkMuted)
                                DSZoneStatusBadge(status: zone.status ?? "active")
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.dsInkMuted)
                    }
                    .padding(.vertical, 4)
                }
                .foregroundStyle(Color.dsInk)
            }
            .onDelete { offsets in
                offsets.map { zones[$0] }.forEach { deleteZone($0) }
            }
        }
        .listStyle(.plain)
        .background(Color.dsBackground)
        .scrollContentBackground(.hidden)
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
}

struct EditZoneView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnv: AppEnvironment

    let zone: InfestationZone
    var onSave: () -> Void

    @State private var zoneName: String
    @State private var selectedSpecies: InvasiveSpecies
    @State private var selectedStatus: String
    @State private var isSaving = false

    init(zone: InfestationZone, onSave: @escaping () -> Void) {
        self.zone = zone
        self.onSave = onSave
        _zoneName = State(initialValue: zone.name ?? "")
        _selectedSpecies = State(initialValue: InvasiveSpecies.from(legacyVariant: zone.dominantVariant ?? ""))
        _selectedStatus = State(initialValue: zone.status ?? "active")
    }

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
                dominantSpecies: selectedSpecies,
                status: selectedStatus
            )
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}
