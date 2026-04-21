import SwiftUI

struct ZoneDetailView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let zone: InfestationZone

    @State private var linkedSightings: [SightingLog] = []

    private var snapshots: [InfestationZoneSnapshot] {
        (zone.snapshots?.array as? [InfestationZoneSnapshot] ?? [])
            .sorted { ($0.snapshotDate ?? .distantPast) > ($1.snapshotDate ?? .distantPast) }
    }

    private var dominantSpecies: InvasiveSpecies {
        InvasiveSpecies.from(legacyVariant: zone.dominantVariant ?? "")
    }

    var body: some View {
        List {
            Section("Zone Info") {
                HStack(spacing: DSSpace.md) {
                    SpeciesIndicator(species: dominantSpecies, size: 16, showIcon: true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(zone.name ?? "Unnamed Zone")
                            .font(DSFont.subhead)
                            .foregroundStyle(Color.dsInk)
                        Text(dominantSpecies.displayName)
                            .font(DSFont.caption)
                            .foregroundStyle(Color.dsInk3)
                    }
                    Spacer()
                    DSZoneStatusBadge(status: zone.status ?? "active")
                }
                if let created = zone.createdAt {
                    LabeledContent("Created", value: created.formatted(date: .abbreviated, time: .omitted))
                }
            }

            Section("Boundary Snapshots (\(snapshots.count))") {
                if snapshots.isEmpty {
                    Text("No boundary drawn yet. Use Draw Zone Boundary on the map.")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.dsInk3)
                } else {
                    ForEach(snapshots, id: \.id) { snapshot in
                        VStack(alignment: .leading, spacing: 3) {
                            if let date = snapshot.snapshotDate {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .font(DSFont.callout)
                                    .foregroundStyle(Color.dsInk)
                            }
                            let coords = snapshot.polygonCoordinates as? [[Double]] ?? []
                            Text("\(coords.count) vertices · \(String(format: "%.0f m²", snapshot.area))")
                                .font(DSFont.caption)
                                .foregroundStyle(Color.dsInk3)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section("Linked Sightings (\(linkedSightings.count))") {
                if linkedSightings.isEmpty {
                    Text("No sightings assigned to this zone.")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.dsInk3)
                } else {
                    ForEach(linkedSightings, id: \.id) { sighting in
                        let sp = InvasiveSpecies.from(legacyVariant: sighting.variant ?? "")
                        HStack(spacing: DSSpace.sm) {
                            SpeciesIndicator(species: sp, size: 10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sp.displayName)
                                    .font(DSFont.callout)
                                    .foregroundStyle(Color.dsInk)
                                if let date = sighting.createdAt {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(DSFont.caption)
                                        .foregroundStyle(Color.dsInk3)
                                }
                            }
                            Spacer()
                            Text(InfestationSize(rawValue: sighting.infestationSize ?? "")?.displayName ?? "")
                                .font(DSFont.caption)
                                .foregroundStyle(Color.dsInk3)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(zone.name ?? "Zone Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear { loadLinkedSightings() }
    }

    private func loadLinkedSightings() {
        linkedSightings = (zone.sightings?.allObjects as? [SightingLog] ?? [])
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }
}
