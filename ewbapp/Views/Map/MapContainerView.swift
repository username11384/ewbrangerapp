import SwiftUI
import MapKit

struct MapContainerView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: MapViewModel
    @State private var showLogSheet = false
    @State private var showAddZoneSheet = false

    @State private var actionCard: MapActionCardData?
    @State private var sightingForDetail: SightingLog?
    @State private var zoneForEdit: InfestationZone?

    @State private var drawingZone: InfestationZone?
    @State private var drawVertices: [CLLocationCoordinate2D] = []
    @State private var showZonePicker = false
    @State private var zoneForDetail: InfestationZone?
    @State private var showTimeline = false

    init() {
        _viewModel = StateObject(wrappedValue: MapViewModel(
            persistence: AppEnvironment.shared.persistence
        ))
    }

    var isDrawing: Bool { drawingZone != nil }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                MapView(
                    mapType: viewModel.mapType,
                    annotations: viewModel.filteredSightings.map { SightingAnnotation(sighting: $0) },
                    patrolAnnotations: viewModel.filteredPatrols,
                    zones: viewModel.zones,
                    showZones: viewModel.showZones,
                    tileOverlay: OfflineTileManager.shared.tileOverlay(),
                    onSelectSighting: { sighting, point in
                        let variant = LantanaVariant(rawValue: sighting.variant ?? "")?.displayName ?? "Sighting"
                        let size = InfestationSize(rawValue: sighting.infestationSize ?? "")?.displayName
                        actionCard = MapActionCardData(
                            title: variant, subtitle: size, anchor: point,
                            actions: [
                                MapCardAction(label: "View Details", icon: "info.circle", isDestructive: false) {
                                    sightingForDetail = sighting
                                },
                                MapCardAction(label: "Delete", icon: "trash", isDestructive: true) {
                                    deleteSighting(sighting)
                                }
                            ]
                        )
                    },
                    onSelectPatrol: { patrol, point in
                        let date = patrol.startTime.map {
                            let f = DateFormatter(); f.dateStyle = .short; return f.string(from: $0)
                        }
                        actionCard = MapActionCardData(
                            title: patrol.areaName ?? "Patrol", subtitle: date, anchor: point,
                            actions: [
                                MapCardAction(label: "Delete", icon: "trash", isDestructive: true) {
                                    deletePatrol(patrol)
                                }
                            ]
                        )
                    },
                    onSelectZone: { zone, point in
                        actionCard = MapActionCardData(
                            title: zone.name ?? "Zone",
                            subtitle: statusLabel(zone.status),
                            anchor: point,
                            actions: [
                                MapCardAction(label: "View Details", icon: "info.circle", isDestructive: false) {
                                    zoneForDetail = zone
                                },
                                MapCardAction(label: "Edit Zone", icon: "pencil", isDestructive: false) {
                                    zoneForEdit = zone
                                },
                                MapCardAction(label: "Delete", icon: "trash", isDestructive: true) {
                                    deleteZone(zone)
                                }
                            ]
                        )
                    },
                    drawVertices: drawVertices,
                    onMapTapped: isDrawing ? { coord in drawVertices.append(coord) } : nil
                )
                .ignoresSafeArea()

                // Draw mode banner
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
                        .padding().background(Color.black.opacity(0.75))

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
                    // Top-left: map type picker
                    VStack {
                        HStack {
                            Menu {
                                Button {
                                    viewModel.mapType = .satellite
                                } label: {
                                    Label("Satellite", systemImage: viewModel.mapType == .satellite ? "checkmark" : "globe")
                                }
                                Button {
                                    viewModel.mapType = .hybrid
                                } label: {
                                    Label("Hybrid", systemImage: viewModel.mapType == .hybrid ? "checkmark" : "globe")
                                }
                                Button {
                                    viewModel.mapType = .standard
                                } label: {
                                    Label("Standard", systemImage: viewModel.mapType == .standard ? "checkmark" : "map")
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "map")
                                    Text(mapTypeLabel)
                                        .font(.caption.bold())
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                            }
                            .padding(.leading)
                            Spacer()
                        }
                        .padding(.top, 8)
                        Spacer()
                    }

                    // Left side: layer toggle icon stack
                    HStack {
                        LayerToggleView(
                            showSightings: $viewModel.showSightings,
                            showZones: $viewModel.showZones,
                            showPatrols: $viewModel.showPatrols
                        )
                        .padding(.leading)
                        .padding(.bottom, 80)
                        Spacer()
                    }

                    // Bottom bar: clock + FAB
                    VStack(spacing: 8) {
                        Spacer()
                        if showTimeline {
                            TimelineScrubberView(
                                date: $viewModel.timelineDate,
                                range: viewModel.dateRange,
                                isPlaying: viewModel.isPlayingTimeline,
                                onTogglePlay: viewModel.toggleTimeline
                            )
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        HStack(alignment: .center) {
                            Button {
                                withAnimation { showTimeline.toggle() }
                            } label: {
                                Image(systemName: showTimeline ? "clock.fill" : "clock")
                                    .frame(width: 40, height: 40)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
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
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }

                // Floating action card
                if let card = actionCard {
                    MapActionCard(data: card, screenSize: geo.size) {
                        actionCard = nil
                    }
                    .ignoresSafeArea()
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isDrawing)
            .animation(.spring(duration: 0.2), value: actionCard == nil)
        }
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
        .sheet(item: $zoneForDetail, onDismiss: { viewModel.load() }) { zone in
            NavigationStack { ZoneDetailView(zone: zone) }
        }
        .sheet(isPresented: $showZonePicker) {
            ZonePickerSheet(zones: viewModel.zones) { zone in
                drawingZone = zone; drawVertices = []; showZonePicker = false
            }
        }
        .onAppear { viewModel.load() }
    }

    private var mapTypeLabel: String {
        switch viewModel.mapType {
        case .hybrid: return "Hybrid"
        case .standard: return "Standard"
        default: return "Satellite"
        }
    }

    private func statusLabel(_ status: String?) -> String {
        switch status {
        case "underTreatment": return "Under Treatment"
        case "cleared": return "Cleared"
        default: return "Active"
        }
    }

    private func deleteSighting(_ sighting: SightingLog) {
        Task {
            try? await SightingRepository(persistence: appEnv.persistence).deleteSighting(sighting)
            await MainActor.run { viewModel.load() }
        }
    }

    private func deletePatrol(_ patrol: PatrolRecord) {
        Task {
            try? await PatrolRepository(persistence: appEnv.persistence).deletePatrol(patrol)
            await MainActor.run { viewModel.load() }
        }
    }

    private func deleteZone(_ zone: InfestationZone) {
        Task {
            try? await ZoneRepository(persistence: appEnv.persistence).deleteZone(zone)
            await MainActor.run { viewModel.load() }
        }
    }

    private func savePolygon() {
        guard let zone = drawingZone, drawVertices.count >= 3,
              let rangerID = appEnv.authManager.currentRangerID else { return }
        let coordinates = drawVertices.map { [$0.latitude, $0.longitude] }
        Task {
            try? await ZoneRepository(persistence: appEnv.persistence).addSnapshot(to: zone, coordinates: coordinates, area: 0, rangerID: rangerID)
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
