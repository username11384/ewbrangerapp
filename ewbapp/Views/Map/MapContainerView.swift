import SwiftUI
import MapKit

struct MapContainerView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: MapViewModel
    @State private var showLogSheet = false
    @State private var showAddZoneSheet = false
    @State private var selectedSighting: SightingLog?

    init() {
        _viewModel = StateObject(wrappedValue: MapViewModel(
            persistence: AppEnvironment.shared.persistence
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            MapView(
                mapType: viewModel.mapType,
                annotations: viewModel.filteredSightings.map { SightingAnnotation(sighting: $0) },
                zones: viewModel.zones,
                showZones: viewModel.showZones,
                tileOverlay: OfflineTileManager.shared.tileOverlay(),
                onSelectSighting: { selectedSighting = $0 }
            )
            .ignoresSafeArea()

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
                    .pickerStyle(.segmented)
                    .frame(width: 230)
                    .padding()
                }
                Spacer()
            }

            // FAB — bottom-right (menu with sighting + zone)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Menu {
                        Button {
                            showLogSheet = true
                        } label: {
                            Label("Log Sighting", systemImage: "mappin.and.ellipse")
                        }
                        Button {
                            showAddZoneSheet = true
                        } label: {
                            Label("Add Zone", systemImage: "square.dashed")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.green)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showLogSheet, onDismiss: { viewModel.load() }) {
            if let rangerID = appEnv.authManager.currentRangerID {
                LogSightingView(rangerID: rangerID)
            }
        }
        .sheet(isPresented: $showAddZoneSheet, onDismiss: { viewModel.load() }) {
            AddZoneView()
        }
        .sheet(item: $selectedSighting) { sighting in
            NavigationStack {
                SightingDetailView(sighting: sighting)
            }
        }
        .onAppear { viewModel.load() }
    }
}
