import SwiftUI
import MapKit

struct MapContainerView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: MapViewModel
    @State private var showLogSheet = false
    @State private var showAddZoneSheet = false

    // Selection → drives confirmation dialogs
    @State private var selectedSighting: SightingLog?
    @State private var selectedPatrol: PatrolRecord?
    @State private var selectedZone: InfestationZone?

    // Detail / edit sheets
    @State private var sightingForDetail: SightingLog?
    @State private var zoneForEdit: InfestationZone?

    // Polygon draw mode
    @State private var drawingZone: InfestationZone?
    @State private var drawVertices: [CLLocationCoordinate2D] = []
    @State private var showZonePicker = false

    init() {
        _viewModel = StateObject(wrappedValue: MapViewModel(
            persistence: AppEnvironment.shared.persistence
        ))
    }

    var isDrawing: Bool { drawingZone != nil }

    var body: some View {
        ZStack(alignment: .bottom) {
            MapView(
                mapType: viewModel.mapType,
                annotations: viewModel.filteredSightings.map { SightingAnnotation(sighting: $0) },
                patrolAnnotations: viewModel.filteredPatrols,
                zones: viewModel.zones,
                showZones: viewModel.showZones,
                tileOverlay: OfflineTileManager.shared.tileOverlay(),
                onSelectSighting: { selectedSighting = $0 },
                onSelectPatrol: { selectedPatrol = $0 },
                onSelectZone: { selectedZone = $0 },
                drawVertices: drawVertices,
                onMapTapped: isDrawing ? { coord in drawVertices.append(coord) } : nil
            )
            .ignoresSafeArea()

            // Draw mode banner + controls
            if isDrawing {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Drawing: \(drawingZone?.name ?? "Zone")")
                                .font(.headline).foregroundColor(.white)
                            Text("\(drawVertices.count) vertices — tap map to add points")
                                .font(.caption).foregroundColor(.white.opacity(0.85))
                        }
                        Spacer()
                        if !drawVertices.isEmpty {
                            Button("Undo") { drawVertices.removeLast() }
                                .buttonStyle(.bordered).tint(.white).padding(.trailing, 8)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.75))

                    HStack(spacing: 16) {
                        Button("Cancel") { drawingZone = nil; drawVertices = [] }
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Color(.systemGray5)).cornerRadius(10)

                        Button("Save Polygon") { savePolygon() }
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(drawVertices.count >= 3 ? Color.green : Color.gray)
                            .foregroundColor(.white).cornerRadius(10)
                            .disabled(drawVertices.count < 3)
                    }
                    .padding(.horizontal).padding(.vertical, 10)
                    .background(Color(.systemBackground))
                }
                .transition(.move(edge: .bottom))
            }

            if !isDrawing {
                // Layer toggles — bottom-left
                VStack {
                    Spacer()
                    HStack {
                        LayerToggleView(
                            showSightings: $viewModel.showSightings,
                            showZones: $viewModel.showZones,
                            showPatrols: $viewModel.showPatrols
                        )
                        .padding(.leading)
                        Spacer()
                    }
                    .padding(.bottom, 100)
                }

                // Map type toggle — top-right
                VStack {
                    HStack {
                        Spacer()
                        Picker("Map", selection: $viewModel.mapType) {
                            Text("Satellite").tag(MKMapType.satellite)
                            Text("Hybrid").tag(MKMapType.hybrid)
                            Text("Standard").tag(MKMapType.standard)
                        }
                        .pickerStyle(.segmented).frame(width: 230).padding()
                    }
                    Spacer()
                }

                // FAB — bottom-right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Menu {
                            Button { showLogSheet = true } label: {
                                Label("Log Sighting", systemImage: "mappin.and.ellipse")
                            }
                            Button { showAddZoneSheet = true } label: {
                                Label("Add Zone", systemImage: "square.dashed")
                            }
                            if !viewModel.zones.isEmpty {
                                Button { showZonePicker = true } label: {
                                    Label("Draw Zone Boundary", systemImage: "pencil.tip.crop.circle")
                                }
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.bold()).foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.green).clipShape(Circle()).shadow(radius: 4)
                        }
                        .padding()
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isDrawing)

        // MARK: - Sighting action dialog
        .confirmationDialog(
            sightingTitle,
            isPresented: Binding(get: { selectedSighting != nil }, set: { if !$0 { selectedSighting = nil } }),
            titleVisibility: .visible
        ) {
            Button("View Details") { sightingForDetail = selectedSighting; selectedSighting = nil }
            Button("Delete", role: .destructive) {
                if let s = selectedSighting { deleteSighting(s) }
                selectedSighting = nil
            }
            Button("Cancel", role: .cancel) { selectedSighting = nil }
        }

        // MARK: - Patrol action dialog
        .confirmationDialog(
            patrolTitle,
            isPresented: Binding(get: { selectedPatrol != nil }, set: { if !$0 { selectedPatrol = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let p = selectedPatrol { deletePatrol(p) }
                selectedPatrol = nil
            }
            Button("Cancel", role: .cancel) { selectedPatrol = nil }
        }

        // MARK: - Zone action dialog
        .confirmationDialog(
            zoneTitle,
            isPresented: Binding(get: { selectedZone != nil }, set: { if !$0 { selectedZone = nil } }),
            titleVisibility: .visible
        ) {
            Button("Edit Zone") { zoneForEdit = selectedZone; selectedZone = nil }
            Button("Delete", role: .destructive) {
                if let z = selectedZone { deleteZone(z) }
                selectedZone = nil
            }
            Button("Cancel", role: .cancel) { selectedZone = nil }
        }

        // MARK: - Sheets
        .sheet(isPresented: $showLogSheet, onDismiss: { viewModel.load() }) {
            if let rangerID = appEnv.authManager.currentRangerID {
                LogSightingView(rangerID: rangerID)
            }
        }
        .sheet(isPresented: $showAddZoneSheet, onDismiss: { viewModel.load() }) {
            AddZoneView()
        }
        .sheet(item: $sightingForDetail) { sighting in
            NavigationStack { SightingDetailView(sighting: sighting) }
        }
        .sheet(item: $zoneForEdit, onDismiss: { viewModel.load() }) { zone in
            EditZoneView(zone: zone) { viewModel.load() }
        }
        .sheet(isPresented: $showZonePicker) {
            ZonePickerSheet(zones: viewModel.zones) { zone in
                drawingZone = zone; drawVertices = []; showZonePicker = false
            }
        }
        .onAppear { viewModel.load() }
    }

    // MARK: - Dialog titles
    private var sightingTitle: String {
        guard let s = selectedSighting else { return "Sighting" }
        return LantanaVariant(rawValue: s.variant ?? "")?.displayName ?? "Sighting"
    }
    private var patrolTitle: String {
        selectedPatrol?.areaName ?? "Patrol"
    }
    private var zoneTitle: String {
        selectedZone?.name ?? "Zone"
    }

    // MARK: - Actions
    private func deleteSighting(_ sighting: SightingLog) {
        let repo = SightingRepository(persistence: appEnv.persistence)
        Task {
            try? await repo.deleteSighting(sighting)
            await MainActor.run { viewModel.load() }
        }
    }

    private func deletePatrol(_ patrol: PatrolRecord) {
        let repo = PatrolRepository(persistence: appEnv.persistence)
        Task {
            try? await repo.deletePatrol(patrol)
            await MainActor.run { viewModel.load() }
        }
    }

    private func deleteZone(_ zone: InfestationZone) {
        let repo = ZoneRepository(persistence: appEnv.persistence)
        Task {
            try? await repo.deleteZone(zone)
            await MainActor.run { viewModel.load() }
        }
    }

    private func savePolygon() {
        guard let zone = drawingZone, drawVertices.count >= 3,
              let rangerID = appEnv.authManager.currentRangerID else { return }
        let coordinates = drawVertices.map { [$0.latitude, $0.longitude] }
        let repo = ZoneRepository(persistence: appEnv.persistence)
        Task {
            try? await repo.addSnapshot(to: zone, coordinates: coordinates, area: 0, rangerID: rangerID)
            try? await Task.sleep(nanoseconds: 150_000_000)
            await MainActor.run { drawingZone = nil; drawVertices = []; viewModel.load() }
        }
    }
}

private struct ZonePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let zones: [InfestationZone]
    let onSelect: (InfestationZone) -> Void

    var body: some View {
        NavigationStack {
            List(zones, id: \.id) { zone in
                Button {
                    onSelect(zone)
                } label: {
                    HStack {
                        VariantColourDot(variant: LantanaVariant(rawValue: zone.dominantVariant ?? "") ?? .unknown, size: 12)
                        Text(zone.name ?? "Unnamed Zone")
                        Spacer()
                        Text(zone.status?.capitalized ?? "Active")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle("Select Zone to Draw")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
