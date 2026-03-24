import SwiftUI

struct SightingListView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: SightingListViewModel
    @State private var showLogSheet = false
    @State private var selectedSighting: SightingLog?

    init() {
        _viewModel = StateObject(wrappedValue: SightingListViewModel(
            persistence: AppEnvironment.shared.persistence,
            locationManager: AppEnvironment.shared.locationManager
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.filtered, id: \.id) { sighting in
                    SightingRow(sighting: sighting, distance: viewModel.formattedDistance(sighting))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSighting = sighting
                        }
                }
            }
            .listStyle(.plain)
            .searchable(text: $viewModel.searchText, prompt: "Search by variant or notes")
            .navigationTitle("Sightings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showLogSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showLogSheet, onDismiss: { viewModel.load() }) {
                if let rangerID = appEnv.authManager.currentRangerID {
                    LogSightingView(rangerID: rangerID)
                }
            }
            .navigationDestination(item: $selectedSighting) { sighting in
                SightingDetailView(sighting: sighting)
            }
            .onAppear { viewModel.load() }
        }
    }
}

struct SightingRow: View {
    let sighting: SightingLog
    let distance: String?

    private var variant: LantanaVariant {
        LantanaVariant(rawValue: sighting.variant ?? "") ?? .unknown
    }

    var body: some View {
        HStack(spacing: 12) {
            VariantColourDot(variant: variant, size: 14)
            VStack(alignment: .leading, spacing: 4) {
                Text(variant.displayName)
                    .font(.headline)
                if let date = sighting.createdAt {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(InfestationSize(rawValue: sighting.infestationSize ?? "")?.displayName ?? "")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
                if let dist = distance {
                    Text(dist)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            SyncStatusBadge(status: SyncStatus(rawValue: sighting.syncStatus) ?? .pendingCreate)
        }
        .padding(.vertical, 4)
    }
}
