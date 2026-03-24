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
                        .fill(viewModel.isSyncing ? .orange : .gray)
                        .frame(width: 10, height: 10)
                    Text(viewModel.overallStatus)
                        .font(.callout)
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Peers list
                if viewModel.discoveredPeers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Searching for nearby rangers…")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nearby Rangers")
                            .font(.headline)
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
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
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
                    color: viewModel.isSyncing ? .red : .green
                )
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("End of Day Sync")
        }
    }
}

struct PeerRow: View {
    let peerName: String
    let status: String

    var body: some View {
        HStack {
            Image(systemName: "iphone.circle.fill")
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(peerName)
                    .font(.subheadline.bold())
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
