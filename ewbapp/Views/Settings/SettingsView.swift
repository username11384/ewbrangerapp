import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: SettingsViewModel

    @State private var showEditName = false
    @State private var showChangePIN = false
    @State private var editedName = ""

    init() {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(
            authManager: AppEnvironment.shared.authManager,
            syncEngine: AppEnvironment.shared.syncEngine,
            persistence: AppEnvironment.shared.persistence
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Profile
                Section("Ranger Profile") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(viewModel.currentRangerName.isEmpty ? "—" : viewModel.currentRangerName)
                            .foregroundColor(.secondary)
                    }
                    Button("Edit Name") {
                        editedName = viewModel.currentRangerName
                        showEditName = true
                    }
                    Button("Change PIN") { showChangePIN = true }
                }

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
            .alert("Edit Name", isPresented: $showEditName) {
                TextField("Display name", text: $editedName)
                Button("Save") { viewModel.updateDisplayName(editedName) }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showChangePIN) {
                ChangePINView(viewModel: viewModel)
            }
        }
    }
}

struct ChangePINView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SettingsViewModel
    @State private var oldPIN = ""
    @State private var newPIN = ""
    @State private var confirmPIN = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Current PIN") {
                    SecureField("Current PIN", text: $oldPIN)
                        .keyboardType(.numberPad)
                }
                Section("New PIN") {
                    SecureField("New PIN (min 4 digits)", text: $newPIN)
                        .keyboardType(.numberPad)
                    SecureField("Confirm New PIN", text: $confirmPIN)
                        .keyboardType(.numberPad)
                }
                if let error = viewModel.pinChangeError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Change PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.changePIN(oldPIN: oldPIN, newPIN: newPIN, confirmPIN: confirmPIN)
                        if viewModel.pinChangeSuccess { dismiss() }
                    }
                    .disabled(oldPIN.isEmpty || newPIN.isEmpty || confirmPIN.isEmpty)
                }
            }
        }
    }
}
