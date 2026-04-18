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

    private var unsyncedCount: Int {
        viewModel.sightings.filter {
            let s = SyncStatus(rawValue: $0.syncStatus)
            return s == .pendingCreate || s == .pendingUpdate
        }.count
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    filterBar
                    sightingList
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

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sightings")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.ink)
                    .tracking(-0.6)
                Text("\(viewModel.sightings.count) records · \(unsyncedCount) not yet synced")
                    .font(.system(size: 13))
                    .foregroundColor(.ink3)
            }
            Spacer()
            Button {
                showLogSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.euc)
                    .frame(width: 36, height: 36)
                    .background(Color.eucSoft)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 54)
        .padding(.bottom, 12)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                allChip
                ForEach(LantanaVariant.allCases, id: \.rawValue) { variant in
                    variantChip(variant)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var allChip: some View {
        let active = viewModel.filterVariant == nil
        return Button {
            viewModel.filterVariant = nil
        } label: {
            Text("All")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(active ? .white : .ink2)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(active ? Color.euc : Color.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
        }
    }

    private func variantChip(_ variant: LantanaVariant) -> some View {
        let active = viewModel.filterVariant == variant
        return Button {
            viewModel.filterVariant = active ? nil : variant
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(variant.color)
                        .frame(width: 10, height: 10)
                    if active {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 1.5)
                            .frame(width: 10, height: 10)
                    }
                }
                Text(variant.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(active ? .white : .ink2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(active ? variant.color : Color.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
        }
    }

    private var sightingList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.filtered, id: \.id) { sighting in
                    SightingCard(sighting: sighting)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedSighting = sighting }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

private struct SightingCard: View {
    let sighting: SightingLog

    private var variant: LantanaVariant {
        LantanaVariant(rawValue: sighting.variant ?? "") ?? .unknown
    }

    private var size: InfestationSize {
        InfestationSize(rawValue: sighting.infestationSize ?? "") ?? .small
    }

    private var syncKind: SyncStatusKind {
        switch SyncStatus(rawValue: sighting.syncStatus) {
        case .synced: return .synced
        case .pendingCreate, .pendingUpdate, .pendingDelete, .none: return .pending
        }
    }

    private var subtitleParts: [String] {
        var parts: [String] = []
        if let name = sighting.ranger?.displayName { parts.append(name) }
        if let zone = sighting.infestationZone?.name { parts.append(zone) }
        return parts
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 18)
                .fill(variant.color)
                .frame(width: 5)
                .clipShape(
                    .rect(
                        topLeadingRadius: 18,
                        bottomLeadingRadius: 18,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                )

            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(variant.displayName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.ink)
                        Text(size.displayName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.ink3)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.paperDeep)
                            .clipShape(Capsule())
                    }
                    HStack(spacing: 4) {
                        let parts = subtitleParts
                        if !parts.isEmpty {
                            Text(parts.joined(separator: " · "))
                                .font(.system(size: 12))
                                .foregroundColor(.ink3)
                                .lineLimit(1)
                        }
                        if let date = sighting.createdAt {
                            if !subtitleParts.isEmpty {
                                Text("·")
                                    .font(.system(size: 12))
                                    .foregroundColor(.ink3)
                            }
                            Text(date, style: .relative)
                                .font(.system(size: 12))
                                .foregroundColor(.ink3)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                SyncBadge(status: syncKind)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
        }
        .background(Color.card)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
        .shadow(color: Color(hex: "281E0A").opacity(0.04), radius: 1, y: 1)
    }
}
