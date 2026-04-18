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
            VariantGuideView()
                .tabItem {
                    Label("Guide", systemImage: "book.fill")
                }
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
        .tint(.ochre)
    }
}

struct MoreView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @State private var selectedTab: String?

    var body: some View {
        NavigationStack(path: $selectedTab) {
            ZStack(alignment: .bottomCenter) {
                ScrollView {
                    VStack(spacing: 24) {
                        ProfileCard()

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ShortcutTile(
                                title: "Mesh sync",
                                icon: "antenna.radiowaves.left.and.right",
                                background: Color.ochreSoft,
                                iconColor: Color.ochre,
                                action: { selectedTab = "meshSync" }
                            )
                            ShortcutTile(
                                title: "Tasks",
                                icon: "checkmark.circle.fill",
                                background: Color.eucSoft,
                                iconColor: Color.euc,
                                action: { selectedTab = "tasks" }
                            )
                            ShortcutTile(
                                title: "Pesticide stock",
                                icon: "drop.fill",
                                background: Color.statusActiveSoft,
                                iconColor: Color.statusActive,
                                action: { selectedTab = "pesticide" }
                            )
                            ShortcutTile(
                                title: "Sighting history",
                                icon: "eye.fill",
                                background: Color.paperDeep,
                                iconColor: Color.ink2,
                                action: { selectedTab = "sightings" }
                            )
                        }
                        .padding(.horizontal, 16)

                        VStack(spacing: 0) {
                            NavigationLink(value: "guide") {
                                HStack(spacing: 16) {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.ochre)
                                        .frame(width: 24)
                                    Text("Help & training videos")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.ink)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.ink3)
                                }
                                .padding(16)
                            }
                            Divider()
                                .padding(.horizontal, 16)
                            NavigationLink(value: "about") {
                                HStack(spacing: 16) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.ochre)
                                        .frame(width: 24)
                                    Text("About this app")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.ink)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.ink3)
                                }
                                .padding(16)
                            }
                        }
                        .background(Color.card)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
                        .padding(.horizontal, 16)

                        Spacer()
                            .frame(height: 80)
                    }
                    .padding(.vertical, 20)
                }

                VStack(spacing: 12) {
                    Button(action: {
                        appEnv.authManager.logout()
                    }) {
                        Text("Sign off")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.ink3)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.paper.opacity(0.6))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .background(Color.paper)
            }
            .navigationTitle("More")
            .navigationDestination(isPresented: .constant(selectedTab == "meshSync")) {
                MeshSyncView()
            }
            .navigationDestination(isPresented: .constant(selectedTab == "tasks")) {
                TaskListView()
            }
            .navigationDestination(isPresented: .constant(selectedTab == "pesticide")) {
                PesticideListView()
            }
            .navigationDestination(isPresented: .constant(selectedTab == "sightings")) {
                SightingListView()
            }
        }
    }
}

struct ProfileCard: View {
    @EnvironmentObject var appEnv: AppEnvironment

    var body: some View {
        let ranger = appEnv.authManager.currentRanger
        let displayName = ranger?.displayName ?? "Ranger"
        let initials = displayName
            .split(separator: " ")
            .map { String($0.prefix(1)).uppercased() }
            .joined()

        let toneColors: [Color] = [.ochreDeep, .euc, .ochre, .bark, .statusCleared]
        let toneIndex = abs(displayName.hashValue) % 5
        let toneColor = toneColors[toneIndex]

        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(toneColor)
                    Text(initials)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.ink)
                    if let role = ranger?.role {
                        Text(role)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.ink3)
                    }
                }
                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "wifi.off")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Offline")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.statusTreat)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.statusTreatSoft)
                .cornerRadius(6)
            }
            .padding(16)
            .background(Color.card)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
        }
        .padding(.horizontal, 16)
    }
}

struct ShortcutTile: View {
    let title: String
    let icon: String
    let background: Color
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(background)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
        }
    }
}
