import SwiftUI

// MARK: - Zone Conflict Model

struct ZoneConflict: Identifiable {
    let id = UUID()
    let zoneName: String
    let myVersion: ConflictVersion
    let peerVersion: ConflictVersion
    var resolution: ConflictResolution?
    var mergePreview: ConflictResolver.ZoneMergePreview?

    struct ConflictVersion {
        let rangerName: String
        let editedAt: Date
        let areaM2: Int

        var timeAgo: String {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: editedAt, relativeTo: Date())
        }
    }

    enum ConflictResolution {
        case keptMine
        case keptTheirs
        case merged
    }

    // MARK: - Demo Data

    static let defaultPeerNames = ["Bob Smith", "Carol White"]

    static func demoConflicts(
        currentRangerName: String,
        peerNames: [String]
    ) -> [ZoneConflict] {
        let peers = peerNames.isEmpty ? defaultPeerNames : peerNames
        let peer1 = peers.indices.contains(0) ? peers[0] : defaultPeerNames[0]
        let peer2 = peers.indices.contains(1) ? peers[1] : peer1

        return [
            ZoneConflict(
                zoneName: "Southern Scrub Belt",
                myVersion: ConflictVersion(
                    rangerName: currentRangerName,
                    editedAt: Date().addingTimeInterval(-2 * 60 * 60),
                    areaM2: 24500
                ),
                peerVersion: ConflictVersion(
                    rangerName: peer1,
                    editedAt: Date().addingTimeInterval(-45 * 60),
                    areaM2: 24620
                ),
                resolution: nil,
                mergePreview: nil
            ),
            ZoneConflict(
                zoneName: "Creek Line East",
                myVersion: ConflictVersion(
                    rangerName: currentRangerName,
                    editedAt: Date().addingTimeInterval(-26 * 60 * 60),
                    areaM2: 18300
                ),
                peerVersion: ConflictVersion(
                    rangerName: peer2,
                    editedAt: Date().addingTimeInterval(-3 * 60 * 60),
                    areaM2: 18420
                ),
                resolution: nil,
                mergePreview: nil
            ),
            ZoneConflict(
                zoneName: "Riparian Buffer",
                myVersion: ConflictVersion(
                    rangerName: currentRangerName,
                    editedAt: Date().addingTimeInterval(-6 * 60 * 60),
                    areaM2: 31200
                ),
                peerVersion: ConflictVersion(
                    rangerName: peer1,
                    editedAt: Date().addingTimeInterval(-2 * 60 * 60),
                    areaM2: 31100
                ),
                resolution: nil,
                mergePreview: nil
            )
        ]
    }
}

// MARK: - Conflict Resolver View

struct ConflictResolverView: View {
    @EnvironmentObject private var appEnv: AppEnvironment
    @State private var conflicts: [ZoneConflict] = []

    private var unresolvedCount: Int {
        conflicts.filter { $0.resolution == nil }.count
    }

    private var currentRangerName: String {
        guard let rangerID = appEnv.authManager.currentRangerID else { return "Current Ranger" }
        let predicate = NSPredicate(format: "id == %@", rangerID as CVarArg)
        return (try? appEnv.persistence.mainContext.fetchFirst(RangerProfile.self, predicate: predicate))?.displayName
            ?? "Current Ranger"
    }

    private var peerNames: [String] {
        let currentID = appEnv.authManager.currentRangerID
        let all = (try? appEnv.persistence.mainContext.fetchAll(RangerProfile.self)) ?? []
        let peers = all
            .filter { $0.id != currentID }
            .compactMap { $0.displayName }
            .sorted()
        return peers.isEmpty ? ZoneConflict.defaultPeerNames : peers
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            VStack(spacing: DSSpace.lg) {
                // Header card
                VStack(alignment: .leading, spacing: DSSpace.sm) {
                    HStack(spacing: DSSpace.md) {
                        Image(systemName: unresolvedCount > 0 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(unresolvedCount > 0 ? Color.dsStatusActive : Color.dsStatusCleared)

                        VStack(alignment: .leading, spacing: 2) {
                            if unresolvedCount > 0 {
                                Text("\(unresolvedCount) conflict\(unresolvedCount == 1 ? "" : "s") need resolution")
                                    .font(DSFont.headline)
                                    .foregroundStyle(Color.dsInk)
                                Text("Zone boundaries edited offline by multiple rangers")
                                    .font(DSFont.caption)
                                    .foregroundStyle(Color.dsInk3)
                            } else {
                                Text("All resolved ✓")
                                    .font(DSFont.headline)
                                    .foregroundStyle(Color.dsStatusCleared)
                                Text("Conflict detection enabled · Last sync check complete")
                                    .font(DSFont.caption)
                                    .foregroundStyle(Color.dsInk3)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(DSSpace.lg)
                .dsCard(padding: 0)

                // Ambient note
                HStack(spacing: DSSpace.sm) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.dsInk3)
                    Text("Conflict detected during Day Sync · LWW disabled for zone boundaries")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.dsInk3)
                    Spacer()
                }
                .padding(DSSpace.md)
                .background(Color.dsSurface)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))

                // Conflict list
                ScrollView {
                    VStack(spacing: DSSpace.md) {
                        ForEach($conflicts) { $conflict in
                            ConflictCard(conflict: $conflict)
                        }
                    }
                }

                Spacer()
            }
            .padding(DSSpace.lg)
        }
        .navigationTitle("Zone Conflicts")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard conflicts.isEmpty else { return }
            conflicts = ZoneConflict.demoConflicts(
                currentRangerName: currentRangerName,
                peerNames: peerNames
            )
        }
    }
}

// MARK: - Conflict Card

private struct ConflictCard: View {
    @Binding var conflict: ZoneConflict

    var body: some View {
        if let resolution = conflict.resolution {
            // Resolved state — collapsed
            HStack(spacing: DSSpace.md) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.dsStatusCleared)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Resolved: \(conflict.zoneName)")
                        .font(DSFont.subhead)
                        .foregroundStyle(Color.dsInk)
                    if resolution == .merged, let mergePreview = conflict.mergePreview {
                        Text("Merged draft: \(mergePreview.baseRangerName)'s newest boundary · \(formattedArea(mergePreview.mergedAreaM2))")
                            .font(DSFont.caption)
                            .foregroundStyle(Color.dsInk3)
                    } else {
                        Text("Kept \(resolutionLabel(resolution))'s version")
                            .font(DSFont.caption)
                            .foregroundStyle(Color.dsInk3)
                    }
                }

                Spacer()
            }
            .padding(DSSpace.md)
            .dsCard(padding: 0)
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        } else {
            // Unresolved state — full card
            VStack(spacing: DSSpace.md) {
                // Title
                HStack(spacing: DSSpace.sm) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.dsAccent)
                    Text(conflict.zoneName)
                        .font(DSFont.headline)
                        .foregroundStyle(Color.dsInk)
                    Spacer()
                }

                Divider().opacity(0.5)

                // Two versions side by side
                HStack(spacing: DSSpace.md) {
                    ConflictVersionView(
                        title: "Your Version",
                        version: conflict.myVersion,
                        isSelected: false
                    )

                    ConflictVersionView(
                        title: "Peer Version",
                        version: conflict.peerVersion,
                        isSelected: false
                    )
                }

                Divider().opacity(0.5)

                // Action buttons
                VStack(spacing: DSSpace.sm) {
                    Button {
                        withAnimation { conflict.resolution = .keptMine }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Keep Mine")
                                .font(DSFont.subhead.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.dsPrimary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                    }

                    HStack(spacing: DSSpace.sm) {
                        Button {
                            withAnimation { conflict.resolution = .keptTheirs }
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Keep Theirs")
                                    .font(DSFont.subhead.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.dsAccent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                        }

                        Button {
                            let preview = ConflictResolver.previewZoneMerge(
                                mine: ConflictResolver.ZoneBoundaryVersion(
                                    rangerName: conflict.myVersion.rangerName,
                                    editedAt: conflict.myVersion.editedAt,
                                    areaM2: conflict.myVersion.areaM2
                                ),
                                theirs: ConflictResolver.ZoneBoundaryVersion(
                                    rangerName: conflict.peerVersion.rangerName,
                                    editedAt: conflict.peerVersion.editedAt,
                                    areaM2: conflict.peerVersion.areaM2
                                )
                            )
                            withAnimation {
                                conflict.mergePreview = preview
                                conflict.resolution = .merged
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.merge")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Merge")
                                    .font(DSFont.subhead.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.dsInk3.opacity(0.2))
                            .foregroundStyle(Color.dsInk3)
                            .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                        }
                    }
                }

                if let mergePreview = conflict.mergePreview {
                    mergePreviewView(mergePreview)
                }
            }
            .padding(DSSpace.md)
            .dsCard(padding: 0)
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
    }

    private func resolutionLabel(_ resolution: ZoneConflict.ConflictResolution) -> String {
        switch resolution {
        case .keptMine: return "your"
        case .keptTheirs: return "their"
        case .merged: return "merged"
        }
    }

    private func formattedArea(_ areaM2: Int) -> String {
        "\(areaM2.formatted()) m²"
    }

    @ViewBuilder
    private func mergePreviewView(_ preview: ConflictResolver.ZoneMergePreview) -> some View {
        VStack(alignment: .leading, spacing: DSSpace.xs) {
            HStack(spacing: DSSpace.sm) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.dsPrimary)
                Text("Merge draft")
                    .font(DSFont.badge)
                    .foregroundStyle(Color.dsPrimary)
            }

            Text("\(preview.baseRangerName)'s newest boundary is the base draft. Merged review area: \(formattedArea(preview.mergedAreaM2)).")
                .font(DSFont.callout)
                .foregroundStyle(Color.dsInk2)

            Text(preview.reviewNote)
                .font(DSFont.caption)
                .foregroundStyle(Color.dsInk3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DSSpace.md)
        .background(Color.dsPrimarySoft)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
    }
}

// MARK: - Conflict Version View

private struct ConflictVersionView: View {
    let title: String
    let version: ZoneConflict.ConflictVersion
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            Text(title)
                .font(DSFont.caption.weight(.semibold))
                .foregroundStyle(Color.dsInk3)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.dsPrimary)
                    Text(version.rangerName)
                        .font(DSFont.callout.weight(.semibold))
                        .foregroundStyle(Color.dsInk)
                }

                Text(version.timeAgo)
                    .font(DSFont.caption)
                    .foregroundStyle(Color.dsInk3)

                HStack(spacing: 4) {
                    Image(systemName: "square.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.dsAccent)
                    Text("\(version.areaM2)m²")
                        .font(DSFont.footnote.weight(.semibold))
                        .foregroundStyle(Color.dsInk)
                }
            }
            .padding(DSSpace.sm)
            .background(Color.dsSurface)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.xs, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConflictResolverView()
    }
}
