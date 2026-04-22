import SwiftUI
import CoreData

/// Fake animated mesh sync view for the demo branch.
/// Discovers the other two rangers dynamically based on who is logged in.
struct DemoMeshSyncView: View {
    enum Phase { case idle, discovering, syncing, done }

    @EnvironmentObject private var appEnv: AppEnvironment

    @State private var phase: Phase = .idle
    @State private var peer1Progress: Double = 0
    @State private var peer2Progress: Double = 0
    @State private var peer1Status = "Waiting…"
    @State private var peer2Status = "Waiting…"
    @State private var showPeers = false
    @State private var summary: String? = nil
    @State private var pendingTaskCount: Int = 0
    @State private var totalTaskCount: Int = 0

    /// The two rangers who are NOT the currently logged-in ranger.
    private var peers: [String] {
        let ctx = appEnv.persistence.mainContext
        let all = (try? ctx.fetchAll(RangerProfile.self)) ?? []
        let currentID = appEnv.authManager.currentRangerID
        let others = all
            .filter { $0.id != currentID }
            .compactMap { $0.displayName }
            .sorted()
        guard others.count >= 2 else {
            return ["Ranger A's iPhone", "Ranger B's iPhone"]
        }
        return ["\(others[0])'s iPhone", "\(others[1])'s iPhone"]
    }

    private var unresolvedConflictCount: Int {
        ZoneConflict.demoConflicts.filter { $0.resolution == nil }.count
    }

    private var syncedTaskDisplayCount: Int {
        max(pendingTaskCount, totalTaskCount)
    }

    var body: some View {
        VStack(spacing: 20) {
                // Status banner
                HStack(spacing: 8) {
                    Circle()
                        .fill(bannerColor)
                        .frame(width: 10, height: 10)
                    Text(bannerText)
                        .font(DSFont.callout)
                    Spacer()
                }
                .padding()
                .background(Color.dsSurface)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                .animation(.easeInOut, value: phase)

                if !showPeers {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.dsInk3)
                        Text("Tap Start Sync to find nearby rangers")
                            .foregroundStyle(Color.dsInk3)
                    }
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nearby Rangers")
                            .font(DSFont.headline)
                            .padding(.horizontal)

                        DemoPeerRow(name: peers[0], status: peer1Status, progress: peer1Progress)
                        DemoPeerRow(name: peers[1], status: peer2Status, progress: peer2Progress)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))

                    Spacer()
                }

                if let summary {
                    Text(summary)
                        .font(DSFont.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.dsInk3)
                        .padding(.horizontal)
                        .transition(.opacity)
                }

                if phase == .done {
                    NavigationLink(destination: ConflictResolverView()) {
                        HStack(spacing: DSSpace.md) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.dsAccent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Zone Conflicts Detected")
                                    .font(DSFont.subhead)
                                    .foregroundStyle(Color.dsInk)
                                Text("\(unresolvedConflictCount) boundaries need review")
                                    .font(DSFont.caption)
                                    .foregroundStyle(Color.dsInk3)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.dsInkMuted)
                        }
                        .padding(DSSpace.md)
                        .background(Color.dsCard)
                        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                                .strokeBorder(Color.dsDivider.opacity(0.6), lineWidth: 0.75)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }

                LargeButton(
                    title: buttonTitle,
                    action: { if phase == .idle || phase == .done { runFakeSync() } },
                    color: phase == .done ? Color.dsStatusCleared : Color.dsPrimary
                )
                .disabled(phase == .syncing || phase == .discovering)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.top)
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationTitle("End of Day Sync")
    }

    // MARK: - Computed
    private var bannerColor: Color {
        switch phase {
        case .idle:        return Color.dsInk3
        case .discovering: return Color.dsStatusTreat
        case .syncing:     return Color.dsPrimary
        case .done:        return Color.dsStatusCleared
        }
    }

    private var bannerText: String {
        switch phase {
        case .idle:        return "Not syncing"
        case .discovering: return "Searching for nearby rangers…"
        case .syncing:     return "Syncing with nearby devices…"
        case .done:        return "Sync complete — all records up to date"
        }
    }

    private var buttonTitle: String {
        switch phase {
        case .idle:        return "Start Sync"
        case .discovering: return "Searching…"
        case .syncing:     return "Syncing…"
        case .done:        return "Sync Again"
        }
    }

    // MARK: - Fake animation + real task sync

    private func runFakeSync() {
        // Snapshot counts before the animation so the summary shows real numbers.
        let ctx = appEnv.persistence.mainContext
        let allTasks = (try? ctx.fetchAll(RangerTask.self)) ?? []
        totalTaskCount = allTasks.count
        pendingTaskCount = allTasks.filter { $0.syncStatus != SyncStatus.synced.rawValue }.count

        withAnimation { phase = .discovering; showPeers = false }
        peer1Progress = 0; peer2Progress = 0
        peer1Status = "Waiting…"; peer2Status = "Waiting…"
        summary = nil

        after(1.0) {
            withAnimation { showPeers = true }
            peer1Status = "Connecting…"
        }
        after(1.8) { peer2Status = "Connecting…" }
        after(2.6) {
            phase = .syncing
            peer1Status = "Syncing tasks…"
            peer2Status = "Syncing tasks…"
        }

        let p1Ticks: [(Double, Double)] = [
            (2.9, 0.12), (3.2, 0.28), (3.5, 0.44),
            (3.8, 0.61), (4.1, 0.75), (4.4, 0.89), (4.8, 1.0)
        ]
        for (delay, value) in p1Ticks {
            after(delay) { withAnimation(.linear(duration: 0.25)) { peer1Progress = value } }
        }

        let p2Ticks: [(Double, Double)] = [
            (3.1, 0.09), (3.4, 0.22), (3.7, 0.38),
            (4.0, 0.55), (4.3, 0.70), (4.6, 0.84), (5.1, 1.0)
        ]
        for (delay, value) in p2Ticks {
            after(delay) { withAnimation(.linear(duration: 0.25)) { peer2Progress = value } }
        }

        let half = (syncedTaskDisplayCount + 1) / 2
        after(4.8) { peer1Status = "Complete — \(half) tasks synced" }
        after(5.1) { peer2Status = "Complete — \(syncedTaskDisplayCount - half) tasks synced" }
        after(5.4) {
            // Actually mark all pending tasks as synced in CoreData.
            flushPendingTasks()
            withAnimation {
                phase   = .done
                summary = "Sync complete. 3 rangers up to date.\n\(totalTaskCount) tasks · \(unresolvedConflictCount) conflicts"
            }
        }
    }

    /// Marks every RangerTask with a non-synced status as synced.
    /// This is what makes task changes visible across rangers after the demo sync.
    private func flushPendingTasks() {
        let bgCtx = appEnv.persistence.backgroundContext
        bgCtx.perform {
            let pred = NSPredicate(format: "syncStatus != %d", SyncStatus.synced.rawValue)
            guard let pending = try? bgCtx.fetchAll(RangerTask.self, predicate: pred),
                  !pending.isEmpty else { return }
            for task in pending {
                task.syncStatus = SyncStatus.synced.rawValue
            }
            try? bgCtx.save()
        }
    }

    private func after(_ seconds: Double, _ block: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: block)
    }
}

// MARK: - Peer row
private struct DemoPeerRow: View {
    let name: String
    let status: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "iphone.circle.fill")
                    .foregroundStyle(Color.dsPrimary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(name).font(DSFont.subhead.bold())
                    Text(status).font(DSFont.caption).foregroundStyle(Color.dsInk3)
                }
                Spacer()
                if progress >= 1.0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dsStatusCleared)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            if progress > 0 && progress < 1.0 {
                ProgressView(value: progress)
                    .tint(Color.dsPrimary)
                    .transition(.opacity)
            }
        }
        .padding(DSSpace.md)
        .background(Color.dsSurface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
        .padding(.horizontal)
        .animation(.easeInOut, value: progress)
    }
}
