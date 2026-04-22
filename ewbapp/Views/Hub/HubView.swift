import SwiftUI

// MARK: - HubView
// The "More" replacement — ranger profile, quick links to dashboard, supplies, sync, and settings.

struct HubView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @State private var tilesAppeared = false

    private var ranger: RangerProfile? {
        guard let id = appEnv.authManager.currentRangerID else { return nil }
        return try? appEnv.persistence.mainContext.fetchFirst(
            RangerProfile.self,
            predicate: NSPredicate(format: "id == %@", id as CVarArg)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile card
                    HubProfileCard(ranger: ranger)
                        .padding(.horizontal, DSSpace.lg)
                        .padding(.top, DSSpace.lg)

                    // Quick access grid — stagger tiles on appear
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpace.md) {
                        HubTile(title: "Dashboard", subtitle: "Stats & progress",
                                icon: "chart.bar.fill", accent: Color.dsPrimary, index: 0,
                                appeared: tilesAppeared) { DashboardView() }
                        HubTile(title: "Supplies", subtitle: "Herbicide stock",
                                icon: "flask.fill", accent: Color.dsAccent, index: 1,
                                appeared: tilesAppeared) { PesticideListView() }
                        HubTile(title: "Day Sync", subtitle: "Mesh sync devices",
                                icon: "antenna.radiowaves.left.and.right", accent: Color(hex: "2E7A6B"), index: 2,
                                appeared: tilesAppeared) { DemoMeshSyncView() }
                        HubTile(title: "Zones", subtitle: "Manage areas",
                                icon: "square.dashed", accent: Color(hex: "7B5EA8"), index: 3,
                                appeared: tilesAppeared) { ZoneListView() }
                        HubTile(title: "Cloud Sync", subtitle: "Supabase · S3",
                                icon: "cloud.fill", accent: Color(hex: "3ECF8E"), index: 4,
                                appeared: tilesAppeared) { DemoLiveSyncView() }
                        HubTile(title: "Handover", subtitle: "End of shift report",
                                icon: "doc.text.fill", accent: Color(hex: "8B5E3C"), index: 5,
                                appeared: tilesAppeared) { ShiftHandoverView() }
                        HubTile(title: "Equipment", subtitle: "Maintenance logs",
                                icon: "wrench.and.screwdriver.fill", accent: Color(hex: "8B5E3C"), index: 6,
                                appeared: tilesAppeared) { EquipmentListView() }
                        HubTile(title: "Hazards", subtitle: "Log field hazards",
                                icon: "exclamationmark.triangle.fill", accent: Color(hex: "C94040"), index: 7,
                                appeared: tilesAppeared) { HazardLogView() }
                    }
                    .padding(.horizontal, DSSpace.lg)
                    .padding(.top, DSSpace.lg)

                    // Settings link
                    VStack(spacing: 0) {
                        NavigationLink(destination: SettingsView()) {
                            HStack(spacing: DSSpace.md) {
                                Image(systemName: "gear")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.dsInk2)
                                    .frame(width: 24)
                                Text("Settings")
                                    .font(DSFont.body)
                                    .foregroundStyle(Color.dsInk)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.dsInkMuted)
                            }
                            .padding(DSSpace.lg)
                        }
                    }
                    .dsCard(padding: 0)
                    .padding(.horizontal, DSSpace.lg)
                    .padding(.top, DSSpace.xl)

                    // Sign off
                    Button {
                        appEnv.authManager.logout()
                    } label: {
                        Text("Sign Off")
                            .font(DSFont.subhead)
                            .foregroundStyle(Color.dsInk3)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.dsSurface)
                            .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                                    .strokeBorder(Color.dsDivider, lineWidth: 0.75)
                            )
                    }
                    .padding(.horizontal, DSSpace.lg)
                    .padding(.top, DSSpace.md)
                    .padding(.bottom, DSSpace.xxxl)
                }
            }
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationTitle("Hub")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                guard !tilesAppeared else { return }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.05)) {
                    tilesAppeared = true
                }
            }
        }
    }
}

// MARK: - Hub Profile Card

private struct HubProfileCard: View {
    let ranger: RangerProfile?

    private var initials: String {
        let name = ranger?.displayName ?? "Ranger"
        let parts = name.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }

    private var roleLabel: String {
        (ranger?.role ?? "Ranger")
            .replacingOccurrences(of: "seniorRanger", with: "Senior Ranger")
            .replacingOccurrences(of: "coordinator", with: "Coordinator")
    }

    private var avatarColor: Color {
        let name = ranger?.displayName ?? ""
        let palette: [Color] = [.dsAccent, .dsPrimary, Color(hex: "7B5EA8"), Color(hex: "2E7A6B"), Color(hex: "C4A32E")]
        let idx = abs(name.hashValue) % palette.count
        return palette[idx]
    }

    var body: some View {
        HStack(spacing: DSSpace.lg) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 56, height: 56)
                Text(initials)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Name + role
            VStack(alignment: .leading, spacing: 2) {
                Text(ranger?.displayName ?? "Ranger")
                    .font(DSFont.headline)
                    .foregroundStyle(Color.dsInk)
                Text(roleLabel)
                    .font(DSFont.callout)
                    .foregroundStyle(Color.dsInk3)
            }

            Spacer()

            // YAC badge
            VStack(spacing: 2) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.dsPrimary)
                Text("YAC")
                    .font(DSFont.badge)
                    .foregroundStyle(Color.dsPrimary)
            }
            .padding(.horizontal, DSSpace.sm)
            .padding(.vertical, DSSpace.xs)
            .background(Color.dsPrimarySoft)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.xs, style: .continuous))
        }
        .dsCard()
    }
}

// MARK: - Hub Tile

private struct HubTile<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let index: Int
    let appeared: Bool
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: DSSpace.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(accent)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.dsInkMuted)
                }
                Spacer()
                Text(title)
                    .font(DSFont.subhead)
                    .foregroundStyle(Color.dsInk)
                Text(subtitle)
                    .font(DSFont.caption)
                    .foregroundStyle(Color.dsInk3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 96)
            .padding(DSSpace.md)
            .background(Color.dsCard)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous)
                    .strokeBorder(Color.dsDivider.opacity(0.6), lineWidth: 0.75)
            )
            .shadow(color: Color.dsInk.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9, anchor: .center)
        .animation(
            .spring(response: 0.45, dampingFraction: 0.72)
                .delay(Double(index) * 0.06),
            value: appeared
        )
    }
}
