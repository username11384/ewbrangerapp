import SwiftUI

struct SightingDetailView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: SightingDetailViewModel
    @State private var showTreatmentEntry = false
    @State private var showZonePicker = false
    @State private var followUpTreatment: TreatmentRecord? = nil

    init(sighting: SightingLog) {
        _viewModel = StateObject(wrappedValue: SightingDetailViewModel(
            sighting: sighting,
            persistence: AppEnvironment.shared.persistence
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Species header band
                speciesHeader

                VStack(alignment: .leading, spacing: DSSpace.xl) {
                    // Location
                    detailSection(title: "Location", icon: "location.fill") {
                        Text(String(format: "%.6f, %.6f",
                                    viewModel.sighting.latitude,
                                    viewModel.sighting.longitude))
                            .font(DSFont.mono)
                            .foregroundStyle(Color.dsInk)
                        Text(String(format: "Accuracy ±%.0fm", viewModel.sighting.horizontalAccuracy))
                            .font(DSFont.caption)
                            .foregroundStyle(Color.dsInk3)
                    }

                    // Size
                    detailSection(title: "Observation Scale", icon: "square.resize") {
                        HStack(spacing: DSSpace.sm) {
                            Text(viewModel.size.displayName)
                                .font(DSFont.callout)
                                .foregroundStyle(Color.dsInk)
                            Text(viewModel.size.areaDescription)
                                .font(DSFont.caption)
                                .foregroundStyle(Color.dsInk3)
                        }
                    }

                    // Zone
                    detailSection(title: "Zone", icon: "square.dashed") {
                        HStack {
                            Text(viewModel.assignedZone?.name ?? "Unassigned")
                                .font(DSFont.callout)
                                .foregroundStyle(viewModel.assignedZone != nil ? Color.dsInk : Color.dsInkMuted)
                            Spacer()
                            Button {
                                viewModel.loadZones()
                                showZonePicker = true
                            } label: {
                                Text(viewModel.assignedZone != nil ? "Change" : "Assign")
                                    .font(DSFont.callout)
                                    .foregroundStyle(Color.dsPrimary)
                            }
                        }
                    }

                    // Notes
                    if let notes = viewModel.sighting.notes, !notes.isEmpty {
                        detailSection(title: "Notes", icon: "note.text") {
                            Text(notes)
                                .font(DSFont.body)
                                .foregroundStyle(Color.dsInk2)
                        }
                    }

                    // Photos
                    if !viewModel.photoFilenames.isEmpty {
                        detailSection(title: "Photos", icon: "photo.stack") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DSSpace.sm) {
                                    ForEach(viewModel.photoFilenames, id: \.self) { filename in
                                        PhotoThumbnail(filename: filename)
                                            .frame(width: 110, height: 110)
                                            .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                                    }
                                }
                            }
                        }
                    }

                    // Treatments
                    detailSection(title: "Treatments", icon: "cross.case.fill") {
                        if viewModel.treatments.isEmpty {
                            Text("No treatments recorded yet.")
                                .font(DSFont.callout)
                                .foregroundStyle(Color.dsInkMuted)
                        } else {
                            VStack(spacing: DSSpace.sm) {
                                ForEach(viewModel.treatments, id: \.id) { treatment in
                                    TreatmentRow(treatment: treatment)
                                    if let notes = treatment.outcomeNotes, notes.hasPrefix("📷 After:") {
                                        BeforeAfterCard(
                                            sighting: viewModel.sighting,
                                            treatmentNotes: notes,
                                            species: viewModel.species
                                        )
                                    }
                                    Button {
                                        followUpTreatment = treatment
                                    } label: {
                                        Label("Record Follow-Up", systemImage: "arrow.clockwise.circle.fill")
                                            .font(DSFont.callout)
                                            .foregroundStyle(Color.dsPrimary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 38)
                                            .background(Color.dsPrimarySoft)
                                            .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DSSpace.lg)
                .padding(.top, DSSpace.xl)
                .padding(.bottom, DSSpace.xxxl)
            }
        }
        .background(Color.dsBackground.ignoresSafeArea())
        .navigationTitle("Sighting")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Treatment") { showTreatmentEntry = true }
                    .foregroundStyle(Color.dsPrimary)
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
        .sheet(item: $followUpTreatment) { treatment in
            TreatmentFollowUpView(treatment: treatment) {
                viewModel.loadTreatments()
            }
        }
        .onAppear { viewModel.loadTreatments() }
    }

    // MARK: - Species header

    @ViewBuilder
    private var speciesHeader: some View {
        let species = viewModel.species
        HStack(spacing: DSSpace.lg) {
            ZStack {
                Circle()
                    .fill(species.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: species.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(species.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(species.displayName)
                    .font(DSFont.title)
                    .foregroundStyle(Color.dsInk)
                Text(species.scientificName)
                    .font(DSFont.caption.italic())
                    .foregroundStyle(Color.dsInk3)
            }
            Spacer()
            DSSyncBadge(status: viewModel.syncStatus)
        }
        .padding(DSSpace.lg)
        .background(Color.dsCard)
        .overlay(alignment: .bottom) {
            Divider().overlay(Color.dsDivider)
        }
    }

    // MARK: - Section helper

    @ViewBuilder
    private func detailSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.dsPrimary)
                Text(title)
                    .font(DSFont.headline)
                    .foregroundStyle(Color.dsInk)
            }
            content()
        }
    }
}

// MARK: - Zone Picker Sheet

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
                            .foregroundStyle(Color.dsInkMuted)
                        Spacer()
                        if current == nil {
                            Image(systemName: "checkmark").foregroundStyle(Color.dsPrimary)
                        }
                    }
                }
                .foregroundStyle(Color.dsInk)
                ForEach(zones, id: \.id) { zone in
                    Button {
                        onSelect(zone)
                    } label: {
                        HStack(spacing: DSSpace.sm) {
                            SpeciesIndicator(
                                species: InvasiveSpecies.from(legacyVariant: zone.dominantVariant ?? ""),
                                size: 12
                            )
                            Text(zone.name ?? "Unnamed Zone")
                                .foregroundStyle(Color.dsInk)
                            Spacer()
                            if zone.id == current?.id {
                                Image(systemName: "checkmark").foregroundStyle(Color.dsPrimary)
                            }
                        }
                    }
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

// MARK: - Treatment Row

struct TreatmentRow: View {
    let treatment: TreatmentRecord

    var body: some View {
        HStack(alignment: .top, spacing: DSSpace.md) {
            let method = TreatmentMethod(rawValue: treatment.method ?? "")
            Image(systemName: method?.systemIconName ?? "cross.case.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.dsPrimary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(method?.displayName ?? (treatment.method ?? ""))
                        .font(DSFont.callout)
                        .foregroundStyle(Color.dsInk)
                    Spacer()
                    if let date = treatment.treatmentDate {
                        Text(date, style: .date)
                            .font(DSFont.caption)
                            .foregroundStyle(Color.dsInk3)
                    }
                }
                if let notes = treatment.outcomeNotes, !notes.isEmpty {
                    let display = notes.hasPrefix("📷 After:") ? stripPhotoPrefix(notes) : notes
                    if !display.isEmpty {
                        Text(display)
                            .font(DSFont.caption)
                            .foregroundStyle(Color.dsInk2)
                    }
                }
            }
        }
        .padding(DSSpace.md)
        .background(Color.dsSurface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
    }

    private func stripPhotoPrefix(_ notes: String) -> String {
        guard let range = notes.range(of: ". ") else { return "" }
        return String(notes[range.upperBound...])
    }
}

// MARK: - Before/After Card

private struct BeforeAfterCard: View {
    let sighting: SightingLog
    let treatmentNotes: String
    let species: InvasiveSpecies

    private var afterCount: Int {
        guard let range = treatmentNotes.range(of: "📷 After: "),
              let end = treatmentNotes[range.upperBound...].range(of: " photo") else { return 0 }
        return Int(treatmentNotes[range.upperBound..<end.lowerBound]) ?? 0
    }

    var body: some View {
        VStack(spacing: DSSpace.sm) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.dsAccent)
                Text("Before / After")
                    .font(DSFont.callout)
                    .foregroundStyle(Color.dsInk)
                Spacer()
                Text("Comparison")
                    .font(DSFont.badge)
                    .foregroundStyle(Color.dsAccent)
                    .padding(.horizontal, DSSpace.sm)
                    .padding(.vertical, 3)
                    .background(Color.dsAccent.opacity(0.12))
                    .clipShape(Capsule())
            }

            HStack(spacing: DSSpace.md) {
                // Before column
                VStack(spacing: DSSpace.sm) {
                    ZStack {
                        Circle()
                            .fill(species.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: species.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(species.color)
                    }
                    Text("Before").font(DSFont.caption).foregroundStyle(Color.dsInk)
                    Text("Sighting logged").font(DSFont.badge).foregroundStyle(Color.dsInk3)
                    if let date = sighting.createdAt {
                        Text(date, style: .date).font(DSFont.badge).foregroundStyle(Color.dsInk3)
                    }
                }
                .frame(maxWidth: .infinity)

                Divider().overlay(Color.dsDivider)

                // After column
                VStack(spacing: DSSpace.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.dsStatusCleared.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.dsStatusCleared)
                    }
                    Text("After").font(DSFont.caption).foregroundStyle(Color.dsInk)
                    Text("Treatment applied").font(DSFont.badge).foregroundStyle(Color.dsInk3)
                    Text("\(afterCount) photo\(afterCount == 1 ? "" : "s")").font(DSFont.badge).foregroundStyle(Color.dsInk3)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(DSSpace.md)
        .background(Color.dsSurface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
    }
}
