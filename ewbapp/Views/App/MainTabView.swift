import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appEnv: AppEnvironment

    var body: some View {
        TabView {
            MapContainerView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
            SightingListView()
                .tabItem {
                    Label("Sightings", systemImage: "list.bullet")
                }
            PatrolView()
                .tabItem {
                    Label("Patrol", systemImage: "figure.walk")
                }
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
    }
}

struct MoreView: View {
    @State private var showAddZone = false

    var body: some View {
        NavigationStack {
            List {
                Section("Field") {
                    NavigationLink(destination: VariantGuideView()) {
                        Label("Variant Guide", systemImage: "book.fill")
                    }
                    NavigationLink(destination: ControlProtocolView()) {
                        Label("Control Protocol", systemImage: "checklist")
                    }
                    Button {
                        showAddZone = true
                    } label: {
                        Label("Add Zone", systemImage: "square.dashed")
                            .foregroundColor(.primary)
                    }
                }
                Section("Reports") {
                    NavigationLink(destination: DashboardView()) {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }
                    NavigationLink(destination: PesticideListView()) {
                        Label("Supplies", systemImage: "flask.fill")
                    }
                }
                Section("Device") {
                    NavigationLink(destination: MeshSyncView()) {
                        Label("End of Day Sync", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More")
            .sheet(isPresented: $showAddZone) {
                AddZoneView()
            }
        }
    }
}
