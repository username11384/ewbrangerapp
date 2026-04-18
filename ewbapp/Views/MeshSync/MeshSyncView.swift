import SwiftUI
import MultipeerConnectivity

enum SyncPhase {
    case discover
    case syncing
    case conflict
    case done
}

struct MeshSyncView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MeshSyncViewModel

    @State private var phase: SyncPhase = .discover
    @State private var selectedPeerName: String?
    @State private var syncFinishedAt: Date?
    @State private var conflictChoice: String?
    @State private var ring1Animate = false
    @State private var ring2Animate = false
    @State private var ring3Animate = false
    @State private var spinRotation: Double = 0

    private let currentRangerName: String
    private let currentRangerInitials: String

    init() {
        let rangerName = (try? AppEnvironment.shared.persistence.mainContext.fetchFirst(
            RangerProfile.self,
            predicate: NSPredicate(format: "isCurrentDevice == YES")
        ))?.displayName ?? "Ranger"
        self.currentRangerName = rangerName
        self.currentRangerInitials = MeshSyncView.initials(from: rangerName)
        _viewModel = StateObject(wrappedValue: MeshSyncViewModel(
            persistence: AppEnvironment.shared.persistence,
            currentRangerName: rangerName
        ))
    }

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 14) {
                        discoveryCard
                        if phase == .conflict {
                            conflictSection
                        }
                        if phase == .done {
                            doneCard
                        }
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if !viewModel.isSyncing {
                viewModel.startDiscovery()
            }
            startRingAnimations()
            startSpinAnimation()
        }
        .onDisappear {
            if viewModel.isSyncing {
                viewModel.stopDiscovery()
            }
        }
        .onChange(of: viewModel.isSyncing) { _, newValue in
            if !newValue && phase == .syncing {
                phase = .done
                syncFinishedAt = Date()
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.ink)
                    .frame(width: 32, height: 32)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("End-of-day sync")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.ink)
                Text("No internet needed · device-to-device")
                    .font(.system(size: 12))
                    .foregroundColor(.ink3)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Discovery card

    private var discoveryCard: some View {
        VStack(spacing: 0) {
            discoveryHeader
            peerList
        }
        .dsCard(padding: 0)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var discoveryHeader: some View {
        ZStack {
            Color.eucDark
            VStack(spacing: 10) {
                ZStack {
                    if phase == .discover || phase == .syncing {
                        ringView(animate: ring1Animate)
                        ringView(animate: ring2Animate)
                        ringView(animate: ring3Animate)
                    }
                    Circle()
                        .fill(Color.ochre)
                        .frame(width: 76, height: 76)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.25), lineWidth: 3)
                        )
                        .overlay(
                            Text(currentRangerInitials)
                                .font(.system(size: 22, weight: .bold, design: .default))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 120, height: 120)
                Text("This device")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(statusSubline)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
        }
    }

    private func ringView(animate: Bool) -> some View {
        Circle()
            .stroke(Color.ochre, lineWidth: 2)
            .frame(width: 100, height: 100)
            .scaleEffect(animate ? 2.2 : 0.4)
            .opacity(animate ? 0.0 : 0.7)
    }

    private var statusSubline: String {
        switch phase {
        case .discover: return "Looking for nearby rangers…"
        case .syncing:  return "Sharing records…"
        case .conflict: return "Review conflicts"
        case .done:     return "All caught up"
        }
    }

    private var peerList: some View {
        VStack(spacing: 0) {
            if viewModel.discoveredPeers.isEmpty {
                HStack {
                    Text("No rangers nearby yet")
                        .font(.system(size: 13))
                        .foregroundColor(.ink3)
                    Spacer()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
            } else {
                ForEach(Array(viewModel.discoveredPeers.enumerated()), id: \.element.displayName) { index, peer in
                    peerRow(peer: peer)
                    if index < viewModel.discoveredPeers.count - 1 {
                        Divider()
                            .background(Color.lineBase.opacity(0.12))
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
        .background(Color.card)
    }

    private func peerRow(peer: MCPeerID) -> some View {
        let initials = MeshSyncView.initials(from: peer.displayName)
        let recordCount = viewModel.peerStatuses[peer.displayName].flatMap { extractRecordCount(from: $0) } ?? 0
        let isSelected = selectedPeerName == peer.displayName && phase == .syncing

        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.eucSoft).frame(width: 40, height: 40)
                Text(initials)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.euc)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(peer.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.ink)
                Text("\(recordCount) records to share")
                    .font(.system(size: 12))
                    .foregroundColor(.ink3)
            }
            Spacer()
            if isSelected {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.ochre)
                        .rotationEffect(.degrees(spinRotation))
                    Text("Syncing…")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.ochre)
                }
            } else if phase == .discover {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.ink3)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            if phase == .discover {
                selectedPeerName = peer.displayName
                phase = .syncing
            }
        }
    }

    private func extractRecordCount(from status: String) -> Int? {
        let digits = status.compactMap { $0.isNumber ? $0 : nil }
        return Int(String(digits))
    }

    // MARK: - Conflict section

    private var conflictSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("1 CONFLICT · WHICH VERSION TO KEEP?")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.ink3)
                .padding(.horizontal, 4)
            conflictCard
        }
    }

    private var conflictCard: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Marina Plains sighting")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.ink)
                Text("Both devices edited the size")
                    .font(.system(size: 12))
                    .foregroundColor(.ink3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)

            Divider().background(Color.lineBase.opacity(0.12))

            HStack(spacing: 0) {
                conflictColumn(
                    key: "yours",
                    label: "YOURS",
                    size: "240 m²",
                    attribution: "You · 2 h ago",
                    note: "Dense mat by the creek edge, two flowering clumps."
                )
                Divider().background(Color.lineBase.opacity(0.12))
                conflictColumn(
                    key: "jarrah",
                    label: "JARRAH'S",
                    size: "310 m²",
                    attribution: "Jarrah · 45 m ago",
                    note: "Walked the full perimeter; larger than first recorded."
                )
            }

            Divider().background(Color.lineBase.opacity(0.12))

            Button {
                if conflictChoice != nil {
                    phase = .done
                    syncFinishedAt = Date()
                }
            } label: {
                Text("Keep this version")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(conflictChoice == nil ? .ink3 : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(conflictChoice == nil ? Color.paperDeep : Color.ochre)
                    .cornerRadius(10)
            }
            .disabled(conflictChoice == nil)
            .padding(12)
        }
        .dsCard(padding: 0)
    }

    private func conflictColumn(key: String, label: String, size: String, attribution: String, note: String) -> some View {
        let isSelected = conflictChoice == key
        return Button {
            conflictChoice = key
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.ink3)
                Text(size)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.ink)
                Text(attribution)
                    .font(.system(size: 11))
                    .foregroundColor(.ink3)
                Text(note)
                    .font(.system(size: 12))
                    .foregroundColor(.ink2)
                    .lineSpacing(1.35)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(isSelected ? Color.eucSoft : Color.card)
            .overlay(
                Rectangle()
                    .fill(isSelected ? Color.euc : Color.clear)
                    .frame(height: 2),
                alignment: .top
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Done card

    private var doneCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.statusClearedSoft).frame(width: 36, height: 36)
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.statusCleared)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("All caught up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.ink)
                    Text("Sync finished at \(formattedFinishTime)")
                        .font(.system(size: 12))
                        .foregroundColor(.ink3)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                statTile(value: "12", label: "Sent")
                statTile(value: "8", label: "Received")
                statTile(value: "1", label: "Resolved")
            }
        }
        .dsCard()
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.ink)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.paperDeep)
        .cornerRadius(12)
    }

    private var formattedFinishTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: syncFinishedAt ?? Date())
    }

    // MARK: - Animations

    private func startRingAnimations() {
        withAnimation(.easeOut(duration: 2.4).repeatForever(autoreverses: false)) {
            ring1Animate = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 2.4).repeatForever(autoreverses: false)) {
                ring2Animate = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 2.4).repeatForever(autoreverses: false)) {
                ring3Animate = true
            }
        }
    }

    private func startSpinAnimation() {
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            spinRotation = 360
        }
    }

    // MARK: - Helpers

    static func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        let result = String(letters).uppercased()
        return result.isEmpty ? "R" : result
    }
}
