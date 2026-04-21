import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appEnv: AppEnvironment

    var body: some View {
        TabView {
            MapContainerView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }

            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: "list.bullet.clipboard.fill")
                }

            SpeciesGuideView()
                .tabItem {
                    Label("Guide", systemImage: "leaf.fill")
                }

            HubView()
                .tabItem {
                    Label("Hub", systemImage: "square.grid.2x2.fill")
                }
        }
        .tint(Color.dsPrimary)
    }
}
