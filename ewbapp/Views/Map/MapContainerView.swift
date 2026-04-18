import SwiftUI
import MapKit
import CoreLocation

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
    @State private var showLayerPanel = false

    init() {
        _viewModel = StateObject(wrappedValue: MapViewModel(
            persistence: AppEnvironment.shared.persistence
        ))
    }

    var isDrawing: Bool { drawingZone != nil }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                MapView(
                    mapType: viewModel.mapType,
                    annotations: viewModel.filteredSightings.map { SightingAnnotation(sighting: $0) },
                    patrolAnnotations: viewModel.filteredPatrols,
                    zones: viewModel.zones,
                    showZones: viewModel.showZones,
                    tileOverlay: OfflineTileManager.shared.tileOverlay(),
                    onSelectSighting: { sighting, point in
                        let variant = LantanaVariant(rawValue: sighting.variant ?? "") ?? .unknown
                        let size = InfestationSize(rawValue: sighting.infestationSize ?? "")?.displayName
                        actionCard = MapActionCardData(
                            title: variant.displayName,
                            subtitle: size,
                            zone: (sighting.zone?.name),
                            ranger: sighting.ranger?.name,
                            accent: variant.color,
                            statusLabel: nil,
                            anchor: point,
                            primary: MapCardAction(label: "Open details", icon: "arrow.up.right", isDestructive: false) {
                                sightingForDetail = sighting
                            },
                            secondary: MapCardAction(label: "Delete", icon: "trash", isDestructive: true) {
                                deleteSighting(sighting)
                            }
                        )
                    },
                    onSelectPatrol: { patrol, point in
                        let date = patrol.startTime.map {
                            let f = DateFormatter(); f.dateStyle = .short; return f.string(from: $0)
                        }
                        actionCard = MapActionCardData(
                            title: patrol.areaName ?? "Patrol",
                            subtitle: date,
                            zone: nil,
                            ranger: patrol.ranger?.name,
                            accent: Color.euc,
                            statusLabel: patrol.endTime == nil ? "Active" : "Completed",
                            anchor: point,
                            primary: nil,
                            secondary: MapCardAction(label: "Delete", icon: "trash", isDestructive: true) {
                                deletePatrol(patrol)
                            }
                        )
                    },
                    onSelectZone: { zone, point in
                        let status = statusLabel(zone.status)
                        actionCard = MapActionCardData(
                            title: zone.name ?? "Zone",
                            subtitle: zone.dominantVariant.flatMap { LantanaVariant(rawValue: $0)?.displayName },
                            zone: nil,
                            ranger: nil,
                            accent: statusAccent(zone.status),
                            statusLabel: status,
                            anchor: point,
                            primary: MapCardAction(label: "Open details", icon: "arrow.up.right", isDestructive: false) {
                                zoneForDetail = zone
                            },
                            secondary: MapCardAction(label: "Edit zone", icon: "pencil", isDestructive: false) {
                                zoneForEdit = zone
                            }
                        )
                    },
                    drawVertices: drawVertices,
                    onMapTapped: isDrawing ? { coord in drawVertices.append(coord) } : nil
                )
                .ignoresSafeArea()

                if isDrawing {
                    drawingBanner
                        .transition(.move(edge: .bottom))
                } else {
                    topChrome(geo: geo)
                    legendChips(geo: geo)
                    fabButton(geo: geo)
                }

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
            .animation(.easeInOut(duration: 0.18), value: showLayerPanel)
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

    // MARK: - Top chrome

    @ViewBuilder
    private func topChrome(geo: GeometryProxy) -> some View {
        ZStack(alignment: .topLeading) {
            HStack {
                locationChip
                    .padding(.leading, 12)
                Spacer()
                VStack(alignment: .trailing, spacing: 10) {
                    iconChromeButton(system: "square.stack.3d.up", active: false) {
                        cycleMapType()
                    }
                    iconChromeButton(system: "line.3.horizontal.decrease", active: showLayerPanel) {
                        showLayerPanel.toggle()
                    }
                    if showLayerPanel {
                        layerPanel
                            .transition(.scale(scale: 0.9, anchor: .topTrailing).combined(with: .opacity))
                    }
                }
                .padding(.trailing, 12)
            }
            .padding(.top, 54)
        }
    }

    private var locationChip: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("PORT STEWART")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(.ink3)
            Text(coordinateLabel)
                .font(.system(size: 13, weight: .bold))
                .monospacedDigit()
                .foregroundColor(.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "F4EFE4").opacity(0.94))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.lineBase.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
    }

    private var coordinateLabel: String {
        if let loc = appEnv.locationManager.currentLocation {
            let lat = loc.coordinate.latitude
            let lon = loc.coordinate.longitude
            let latStr = String(format: "%.2f°%@", abs(lat), lat >= 0 ? "N" : "S")
            let lonStr = String(format: "%.2f°%@", abs(lon), lon >= 0 ? "E" : "W")
            return "\(latStr) · \(lonStr)"
        }
        return "14.49°S · 143.72°E"
    }

    private func iconChromeButton(system: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(active ? .white : .ink)
                .frame(width: 38, height: 38)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 10)
                            .fill(active ? Color.euc : Color(hex: "F4EFE4").opacity(0.94))
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.lineBase.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var layerPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LAYERS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(.ink3)
                .padding(.horizontal, 4)
                .padding(.top, 2)
            layerToggleRow(title: "Sightings", isOn: $viewModel.showSightings)
            layerToggleRow(title: "Zones", isOn: $viewModel.showZones)
            layerToggleRow(title: "Patrol routes", isOn: $viewModel.showPatrols)
        }
        .padding(10)
        .frame(minWidth: 178, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(Color.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.lineBase.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
    }

    private func layerToggleRow(title: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isOn.wrappedValue ? Color.euc : Color.clear)
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isOn.wrappedValue ? Color.euc : Color.lineBase.opacity(0.3), lineWidth: 1.3)
                    if isOn.wrappedValue {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 20, height: 20)

                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.ink)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Legend + FAB

    @ViewBuilder
    private func legendChips(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            legendChip(text: "Active", color: .statusActive)
            legendChip(text: "Treating", color: .statusTreat)
            legendChip(text: "Cleared", color: .statusCleared)
        }
        .position(x: 58, y: geo.size.height - 100 - 36)
    }

    private func legendChip(text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.ink)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            ZStack {
                Capsule().fill(.ultraThinMaterial)
                Capsule().fill(Color(hex: "F4EFE4").opacity(0.94))
            }
        )
        .overlay(Capsule().stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
    }

    @ViewBuilder
    private func fabButton(geo: GeometryProxy) -> some View {
        Menu {
            Button { showLogSheet = true } label: {
                Label("Log sighting", systemImage: "mappin.and.ellipse")
            }
            Button { showAddZoneSheet = true } label: {
                Label("Add zone", systemImage: "square.dashed")
            }
            if !viewModel.zones.isEmpty {
                Button { showZonePicker = true } label: {
                    Label("Draw zone boundary", systemImage: "pencil.tip.crop.circle")
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Color.ochre))
                .overlay(Circle().stroke(Color.ochreDeep, lineWidth: 1.5))
                .shadow(color: Color.ochreDeep.opacity(0.45), radius: 10, y: 6)
        }
        .position(x: geo.size.width - 50, y: geo.size.height - 100 - 30)
    }

    // MARK: - Drawing banner

    private var drawingBanner: some View {
        VStack(spacing: 0) {
            Spacer()
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
                .padding().background(Color.eucDark.opacity(0.9))

                HStack(spacing: 16) {
                    Button("Cancel") { drawingZone = nil; drawVertices = [] }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.paperDeep).foregroundColor(.ink).cornerRadius(10)
                    Button("Save Polygon") { savePolygon() }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(drawVertices.count >= 3 ? Color.euc : Color.ink3)
                        .foregroundColor(.white).cornerRadius(10)
                        .disabled(drawVertices.count < 3)
                }
                .padding(.horizontal).padding(.vertical, 10)
                .background(Color.paper)
            }
        }
    }

    // MARK: - Helpers

    private func cycleMapType() {
        switch viewModel.mapType {
        case .satellite: viewModel.mapType = .standard
        case .standard:  viewModel.mapType = .hybrid
        default:         viewModel.mapType = .satellite
        }
    }

    private func statusLabel(_ status: String?) -> String {
        switch status {
        case "underTreatment": return "Treating"
        case "cleared": return "Cleared"
        default: return "Active"
        }
    }

    private func statusAccent(_ status: String?) -> Color {
        switch status {
        case "underTreatment": return .statusTreat
        case "cleared": return .statusCleared
        default: return .statusActive
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
