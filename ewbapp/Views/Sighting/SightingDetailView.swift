import SwiftUI

struct SightingDetailView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: SightingDetailViewModel
    @State private var showTreatmentEntry = false
    @State private var showZonePicker = false

    init(sighting: SightingLog) {
        _viewModel = StateObject(wrappedValue: SightingDetailViewModel(
            sighting: sighting,
            persistence: AppEnvironment.shared.persistence
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Variant header
                HStack(spacing: 12) {
                    VariantColourDot(variant: viewModel.variant, size: 20)
                    Text(viewModel.variant.displayName)
                        .font(.title2.bold())
                    Spacer()
                    SyncStatusBadge(status: viewModel.syncStatus)
                }
                Divider()
                // Location
                Group {
                    Label("Location", systemImage: "location.fill")
                        .font(.headline)
                    Text(String(format: "%.6f, %.6f", viewModel.sighting.latitude, viewModel.sighting.longitude))
                        .font(.system(.callout, design: .monospaced))
                    Text(String(format: "Accuracy ±%.0fm", viewModel.sighting.horizontalAccuracy))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Divider()
                // Size
                Group {
                    Label("Size", systemImage: "square.resize")
                        .font(.headline)
                    Text(viewModel.size.displayName + " " + viewModel.size.areaDescription)
                }
                // Notes
                if let notes = viewModel.sighting.notes, !notes.isEmpty {
                    Divider()
                    Group {
                        Label("Notes", systemImage: "note.text")
                            .font(.headline)
                        Text(notes)
                            .font(.body)
                    }
                }
                // Photos
                if !viewModel.photoFilenames.isEmpty {
                    Divider()
                    Label("Photos", systemImage: "photo.stack")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.photoFilenames, id: \.self) { filename in
                                PhotoThumbnail(filename: filename)
                                    .frame(width: 120, height: 120)
                            }
                        }
                    }
                }
                Divider()
                // Zone assignment
                Group {
                    HStack {
                        Label("Zone", systemImage: "square.dashed")
                            .font(.headline)
                        Spacer()
                        Button {
                            viewModel.loadZones()
                            showZonePicker = true
                        } label: {
                            Text(viewModel.assignedZone?.name ?? "Unassigned")
                                .font(.callout)
                                .foregroundColor(viewModel.assignedZone != nil ? .primary : .secondary)
                        }
                    }
                }
                Divider()
                // Treatments
                Group {
                    Label("Treatments", systemImage: "cross.case.fill")
                        .font(.headline)
                    if viewModel.treatments.isEmpty {
                        Text("No treatments recorded yet.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.treatments, id: \.id) { treatment in
                            TreatmentRow(treatment: treatment)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Sighting Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Treatment") {
                    showTreatmentEntry = true
                }
            }
        }
        .sheet(isPresented: $showTreatmentEntry) {
            TreatmentEntryView(sighting: viewModel.sighting) {
                viewModel.loadTreatments()
            }
        }
        .sheet(isPresented: $showZonePicker) {
            ZonePickerForSightingSheet(
                zones: viewModel.allZones,
                current: viewModel.assignedZone
            ) { zone in
                viewModel.assignToZone(zone)
                showZonePicker = false
            }
        }
        .onAppear { viewModel.loadTreatments() }
    }
}

private struct ZonePickerForSightingSheet: View {
    @Environment(\.dismiss) private var dismiss
    let zones: [InfestationZone]
    let current: InfestationZone?
    let onSelect: (InfestationZone?) -> Void

    var body: some View {
        NavigationStack {
            List {
                Button {
                    onSelect(nil)
                } label: {
                    HStack {
                        Text("Unassigned")
                            .foregroundColor(.secondary)
                        Spacer()
                        if current == nil {
                            Image(systemName: "checkmark").foregroundColor(.accentColor)
                        }
                    }
                }
                .foregroundColor(.primary)
                ForEach(zones, id: \.id) { zone in
                    Button {
                        onSelect(zone)
                    } label: {
                        HStack(spacing: 10) {
                            VariantColourDot(
                                variant: LantanaVariant(rawValue: zone.dominantVariant ?? "") ?? .unknown,
                                size: 12
                            )
                            Text(zone.name ?? "Unnamed Zone")
                            Spacer()
                            if zone.id == current?.id {
                                Image(systemName: "checkmark").foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Assign to Zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct TreatmentRow: View {
    let treatment: TreatmentRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(TreatmentMethod(rawValue: treatment.method ?? "")?.displayName ?? treatment.method ?? "")
                    .font(.subheadline.bold())
                Spacer()
                if let date = treatment.treatmentDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            if let notes = treatment.outcomeNotes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
