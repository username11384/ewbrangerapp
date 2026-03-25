import SwiftUI
import CoreLocation

struct SettingsView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: SettingsViewModel

    @State private var showEditName = false
    @State private var showChangePIN = false
    @State private var editedName = ""
    @State private var showResetConfirm = false
    @ObservedObject private var devSettings = DeveloperSettings.shared

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
                    Button {
                        viewModel.syncNow()
                    } label: {
                        HStack {
                            Text("Sync Now")
                            if viewModel.isSyncing {
                                Spacer()
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .disabled(viewModel.isSyncing)
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

                // Developer
                Section {
                    Toggle(isOn: $devSettings.spoofLocationEnabled) {
                        Label("Spoof Location", systemImage: "location.slash.fill")
                    }
                    if devSettings.spoofLocationEnabled {
                        Picker("Preset", selection: $devSettings.spoofedPresetName) {
                            Section("Infestation Zones") {
                                ForEach(LocationPreset.all.prefix(6)) {
                                    Text($0.name).tag($0.name)
                                }
                            }
                            Section("Patrol Areas") {
                                ForEach(LocationPreset.all.dropFirst(6)) {
                                    Text($0.name).tag($0.name)
                                }
                            }
                        }
                        if let coord = devSettings.spoofedCoordinate {
                            Text(String(format: "%.4f, %.4f", coord.latitude, coord.longitude))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("GPS spoof takes effect on next location capture or app foreground.")
                }

                Section {
                    Button("Reset App Data") { showResetConfirm = true }
                        .foregroundColor(.secondary)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset App Data",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset All Data", role: .destructive) { viewModel.resetDemoData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all sightings, zones, patrols, and tasks, then restore the original demo data.")
            }
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
