import SwiftUI

struct ZoneDetailView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let zone: InfestationZone

    @State private var linkedSightings: [SightingLog] = []
    @State private var showAssignSighting = false

    private var snapshots: [InfestationZoneSnapshot] {
        (zone.snapshots?.array as? [InfestationZoneSnapshot] ?? [])
            .sorted { ($0.snapshotDate ?? .distantPast) > ($1.snapshotDate ?? .distantPast) }
    }

    var body: some View {
        List {
            Section("Zone Info") {
                HStack {
                    VariantColourDot(
                        variant: LantanaVariant(rawValue: zone.dominantVariant ?? "") ?? .unknown,
                        size: 14
                    )
                    Text(zone.name ?? "Unnamed Zone")
                        .font(.headline)
                    Spacer()
                    statusBadge(zone.status)
                }
                if let dominant = LantanaVariant(rawValue: zone.dominantVariant ?? "") {
                    LabeledContent("Variant", value: dominant.displayName)
                }
                if let created = zone.createdAt {
                    LabeledContent("Created", value: created.formatted(date: .abbreviated, time: .omitted))
                }
            }

            Section("Boundary Snapshots (\(snapshots.count))") {
                if snapshots.isEmpty {
                    Text("No boundary drawn yet. Use Draw Zone Boundary on the map.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(snapshots, id: \.id) { snapshot in
                        VStack(alignment: .leading, spacing: 3) {
                            if let date = snapshot.snapshotDate {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline.bold())
                            }
                            let coords = snapshot.polygonCoordinates as? [[Double]] ?? []
                            Text("\(coords.count) vertices · \(String(format: "%.0f m²", snapshot.area))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section("Linked Sightings (\(linkedSightings.count))") {
                if linkedSightings.isEmpty {
                    Text("No sightings assigned to this zone.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(linkedSightings, id: \.id) { sighting in
                        HStack(spacing: 10) {
                            VariantColourDot(
                                variant: LantanaVariant(rawValue: sighting.variant ?? "") ?? .unknown,
                                size: 10
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LantanaVariant(rawValue: sighting.variant ?? "")?.displayName ?? "Unknown")
                                    .font(.subheadline)
                                if let date = sighting.createdAt {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Text(InfestationSize(rawValue: sighting.infestationSize ?? "")?.displayName ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
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

    @ViewBuilder
    private func statusBadge(_ status: String?) -> some View {
        let (label, color): (String, Color) = {
            switch status {
            case "underTreatment": return ("Treating", .orange)
            case "cleared": return ("Cleared", .green)
            default: return ("Active", .red)
            }
        }()
        Text(label)
            .font(.caption.bold())
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
}
