import SwiftUI
import MapKit

struct SightingDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: SightingDetailViewModel
    @State private var showTreatmentEntry = false
    @State private var showZonePicker = false
    @State private var treatmentsExpanded = true

    init(sighting: SightingLog) {
        _viewModel = StateObject(wrappedValue: SightingDetailViewModel(
            sighting: sighting,
            persistence: AppEnvironment.shared.persistence
        ))
    }

    private var syncKind: SyncStatusKind {
        switch viewModel.syncStatus {
        case .synced: return .synced
        case .pendingCreate, .pendingUpdate, .pendingDelete: return .pending
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 12) {
                        mapThumbnail
                        mainFactsCard
                        treatmentsCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
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

    private var topBar: some View {
        ZStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.ink)
                        .frame(width: 36, height: 36)
                }
                Spacer()
                Button {
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.ink)
                        .frame(width: 36, height: 36)
                }
            }
            Text("Sighting")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.ink)
        }
        .padding(.horizontal, 16)
        .padding(.top, 54)
        .padding(.bottom, 12)
        .background(Color.paper)
    }

    private var mapThumbnail: some View {
        let coord = CLLocationCoordinate2D(
            latitude: viewModel.sighting.latitude,
            longitude: viewModel.sighting.longitude
        )
        let position = MapCameraPosition.region(
            MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
            )
        )
        return ZStack {
            Map(initialPosition: position) {}
                .disabled(true)
                .frame(maxWidth: .infinity)
                .frame(height: 140)
            Circle()
                .fill(viewModel.variant.color)
                .frame(width: 14, height: 14)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        }
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
        .clipped()
    }

    private var mainFactsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(viewModel.variant.color)
                        .frame(width: 44, height: 44)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.variant.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.ink)
                    HStack(spacing: 4) {
                        Text(viewModel.size.displayName)
                            .font(.system(size: 12))
                            .foregroundColor(.ink3)
                        if let zoneName = viewModel.assignedZone?.name {
                            Text("·")
                                .font(.system(size: 12))
                                .foregroundColor(.ink3)
                            Text(zoneName)
                                .font(.system(size: 12))
                                .foregroundColor(.ink3)
                        }
                    }
                }
                Spacer()
                SyncBadge(status: syncKind)
            }

            Rectangle()
                .fill(Color.lineBase.opacity(0.12))
                .frame(height: 0.5)
                .padding(.vertical, 12)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                FactCell(label: "Logged by", value: viewModel.sighting.ranger?.displayName ?? "—")
                FactCell(label: "When", value: viewModel.sighting.createdAt.map { relativeString($0) } ?? "—")
                FactCell(label: "GPS", value: String(format: "%.5f, %.5f", viewModel.sighting.latitude, viewModel.sighting.longitude), mono: true)
                FactCell(label: "Accuracy", value: String(format: "±%.0f m", viewModel.sighting.horizontalAccuracy))
            }

            if let notes = viewModel.sighting.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 13.5))
                    .foregroundColor(.ink2)
                    .lineSpacing(1.4)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.paperDeep)
                    .cornerRadius(10)
                    .padding(.top, 12)
            }
        }
        .dsCard()
    }

    private var treatmentsCard: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    treatmentsExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Treatments · \(viewModel.treatments.count)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.ink)
                    Spacer()
                    Image(systemName: treatmentsExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.ink3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if treatmentsExpanded {
                VStack(spacing: 0) {
                    if !viewModel.treatments.isEmpty {
                        Rectangle()
                            .fill(Color.lineBase.opacity(0.08))
                            .frame(height: 0.5)
                            .padding(.horizontal, 16)

                        ForEach(viewModel.treatments, id: \.id) { treatment in
                            TreatmentDetailRow(treatment: treatment)
                            if treatment.id != viewModel.treatments.last?.id {
                                Rectangle()
                                    .fill(Color.lineBase.opacity(0.08))
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }

                    Rectangle()
                        .fill(Color.lineBase.opacity(0.08))
                        .frame(height: 0.5)
                        .padding(.horizontal, 16)

                    Button {
                        showTreatmentEntry = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Add treatment")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.euc)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(Color.card)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
        .shadow(color: Color(hex: "281E0A").opacity(0.04), radius: 1, y: 1)
    }

    private func relativeString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct FactCell: View {
    let label: String
    let value: String
    var mono: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.ink3)
                .textCase(.uppercase)
                .tracking(0.3)
            Text(value)
                .font(mono ? .system(size: 13, design: .monospaced) : .system(size: 13, weight: .medium))
                .foregroundColor(.ink)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TreatmentDetailRow: View {
    let treatment: TreatmentRecord

    private var method: TreatmentMethod? {
        TreatmentMethod(rawValue: treatment.method ?? "")
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.eucSoft)
                    .frame(width: 36, height: 36)
                Image(systemName: method?.systemIconName ?? "drop.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.euc)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(method?.displayName ?? treatment.method ?? "Treatment")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.ink)
                HStack(spacing: 4) {
                    if let date = treatment.treatmentDate {
                        Text(date, style: .date)
                            .font(.system(size: 12))
                            .foregroundColor(.ink3)
                    }
                    if let name = treatment.ranger?.displayName {
                        Text("·")
                            .font(.system(size: 12))
                            .foregroundColor(.ink3)
                        Text(name)
                            .font(.system(size: 12))
                            .foregroundColor(.ink3)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
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
