import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: SettingsViewModel

    init() {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(
            authManager: AppEnvironment.shared.authManager,
            syncEngine: AppEnvironment.shared.syncEngine
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Sync
                Section("Sync") {
                    HStack {
                        Text("Pending Records")
                        Spacer()
                        Text("\(viewModel.pendingSyncCount)")
                            .foregroundColor(viewModel.pendingSyncCount > 0 ? .orange : .secondary)
                    }
                    if let last = viewModel.lastSyncDate {
                        HStack {
                            Text("Last Synced")
                            Spacer()
                            Text(last, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                    Button("Sync Now") { viewModel.syncNow() }
                        .foregroundColor(.blue)
                }

                // Seasonal
                Section("Field Conditions") {
                    Toggle("Recent Rain Event", isOn: Binding(
                        get: { viewModel.recentRainFlagged },
                        set: { _ in viewModel.toggleRecentRain() }
                    ))
                }

                // Offline maps
                Section("Offline Maps") {
                    switch viewModel.tileStatus {
                    case .available(let version, let coverage):
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tiles Available (\(version))")
                            Text(coverage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    case .unavailable:
                        Label("Tiles not downloaded", systemImage: "map.slash")
                            .foregroundColor(.red)
                    case .downloading(let p):
                        HStack {
                            Text("Downloading…")
                            ProgressView(value: p)
                        }
                    case .checking:
                        Text("Checking…")
                    }
                }

                // App
                Section("App") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }
                    Button("Logout", role: .destructive) {
                        viewModel.logout()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
