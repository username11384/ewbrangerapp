import SwiftUI
import MultipeerConnectivity

struct MeshSyncView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: MeshSyncViewModel
    @State private var lastSyncTime: Date?

    init() {
        let rangerName = (try? AppEnvironment.shared.persistence.mainContext.fetchFirst(
            RangerProfile.self,
            predicate: NSPredicate(format: "isCurrentDevice == YES")
        ))?.displayName ?? "Ranger"
        _viewModel = StateObject(wrappedValue: MeshSyncViewModel(
            persistence: AppEnvironment.shared.persistence,
            currentRangerName: rangerName
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Status banner
                HStack {
                    Circle()
                        .fill(viewModel.isSyncing ? Color.dsStatusTreat : Color.dsInk3)
                        .frame(width: 10, height: 10)
                    Text(viewModel.overallStatus)
                        .font(DSFont.callout)
                    Spacer()
                }
                .padding()
                .background(Color.dsSurface)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))

                // Peers list
                if viewModel.discoveredPeers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.dsInk3)
                        Text("Searching for nearby rangers…")
                            .foregroundStyle(Color.dsInk3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nearby Rangers")
                            .font(DSFont.headline)
                            .padding(.horizontal)
                        ForEach(viewModel.discoveredPeers, id: \.displayName) { peer in
                            PeerRow(
                                peerName: peer.displayName,
                                status: viewModel.peerStatuses[peer.displayName] ?? "Waiting…"
                            )
                        }
                    }
                }

                Spacer()

                // Summary
                if let summary = viewModel.lastSyncSummary {
                    Text(summary)
                        .font(DSFont.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.dsInk3)
                }

                // Start / Stop
                LargeButton(
                    title: viewModel.isSyncing ? "Stop Sync" : "Start Sync",
                    action: {
                        if viewModel.isSyncing {
                            viewModel.stopDiscovery()
                        } else {
                            viewModel.startDiscovery()
                        }
                    },
                    color: viewModel.isSyncing ? Color.dsStatusActive : Color.dsStatusCleared
                )
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("End of Day Sync")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: RangerStatusView()) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .foregroundStyle(Color.dsPrimary)
                    }
                }
            }
        }
    }
}

struct PeerRow: View {
    let peerName: String
    let status: String

    var body: some View {
        HStack {
            Image(systemName: "iphone.circle.fill")
                .foregroundStyle(Color.dsPrimary)
            VStack(alignment: .leading) {
                Text(peerName)
                    .font(DSFont.subhead)
                Text(status)
                    .font(DSFont.caption)
                    .foregroundStyle(Color.dsInk3)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.dsSurface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
        .padding(.horizontal)
    }
}
