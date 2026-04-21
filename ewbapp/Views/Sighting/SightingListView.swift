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
            Group {
                if viewModel.filtered.isEmpty {
                    DSEmptyState(
                        icon: "binoculars",
                        title: "No sightings yet",
                        message: "Tap + to log an invasive plant sighting."
                    )
                } else {
                    List {
                        ForEach(viewModel.filtered, id: \.id) { sighting in
                            SightingCard(
                                sighting: sighting,
                                distance: viewModel.formattedDistance(sighting)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { selectedSighting = sighting }
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.dsBackground)
                        }
                        .onDelete { offsets in
                            offsets.map { viewModel.filtered[$0] }.forEach { viewModel.delete($0) }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.dsBackground)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.dsBackground.ignoresSafeArea())
            .searchable(text: $viewModel.searchText, prompt: "Search species or notes")
            .navigationTitle("Sightings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showLogSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.dsPrimary)
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

// MARK: - Sighting Card

private struct SightingCard: View {
    let sighting: SightingLog
    let distance: String?

    private var species: InvasiveSpecies {
        InvasiveSpecies.from(legacyVariant: sighting.variant ?? "")
    }

    private var size: InfestationSize {
        InfestationSize(rawValue: sighting.infestationSize ?? "") ?? .small
    }

    var body: some View {
        HStack(spacing: 0) {
            // Species accent bar
            Rectangle()
                .fill(species.color)
                .frame(width: 4)

            HStack(alignment: .center, spacing: DSSpace.md) {
                // Species icon circle
                ZStack {
                    Circle()
                        .fill(species.color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: species.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(species.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(species.displayName)
                        .font(DSFont.subhead)
                        .foregroundStyle(Color.dsInk)
                    HStack(spacing: 6) {
                        if let date = sighting.createdAt {
                            Text(date, style: .relative)
                                .font(DSFont.caption)
                                .foregroundStyle(Color.dsInk3)
                        }
                        if let name = sighting.ranger?.displayName {
                            Text("·")
                                .font(DSFont.caption)
                                .foregroundStyle(Color.dsInk3)
                            Text(name.components(separatedBy: " ").first ?? name)
                                .font(DSFont.caption)
                                .foregroundStyle(Color.dsInk3)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    // Size badge
                    Text(size.displayName)
                        .font(DSFont.badge)
                        .foregroundStyle(Color.dsInk2)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.dsSurface)
                        .clipShape(Capsule())

                    if let dist = distance {
                        Text(dist)
                            .font(DSFont.caption)
                            .foregroundStyle(Color.dsInkMuted)
                    }
                }
            }
            .padding(.horizontal, DSSpace.md)
            .padding(.vertical, DSSpace.md)
        }
        .background(Color.dsCard)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                .strokeBorder(Color.dsDivider.opacity(0.6), lineWidth: 0.75)
        )
        .shadow(color: Color.dsInk.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}
