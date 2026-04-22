import SwiftUI

struct RangerStatusView: View {
    @StateObject private var viewModel: RangerStatusViewModel

    init() {
        let env = AppEnvironment.shared
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let rangerName = (try? env.persistence.mainContext.fetchFirst(
            RangerProfile.self,
            predicate: NSPredicate(format: "isCurrentDevice == YES")
        ))?.displayName ?? "Ranger"
        _viewModel = StateObject(wrappedValue: RangerStatusViewModel(
            syncEngine: env.syncEngine,
            deviceID: deviceID,
            rangerName: rangerName
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DSSpace.lg) {
                    myStatusCard
                    assistanceButton
                    nearbyRangersList
                }
                .padding(.horizontal, DSSpace.lg)
                .padding(.vertical, DSSpace.lg)
            }
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationTitle("Ranger Status")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - My Status Card

    private var myStatusCard: some View {
        VStack(alignment: .leading, spacing: DSSpace.md) {
            HStack(spacing: DSSpace.sm) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.dsPrimary)
                Text("My Status")
                    .font(DSFont.headline)
                    .foregroundStyle(Color.dsInk)
                Spacer()
                if let battery = viewModel.myStatus.batteryLevel {
                    batteryIndicator(battery)
                }
            }

            Divider()
                .background(Color.dsDivider)

            // Status picker
            VStack(alignment: .leading, spacing: DSSpace.xs) {
                Text("Current Status")
                    .font(DSFont.caption)
                    .foregroundStyle(Color.dsInk3)

                Picker("Status", selection: Binding(
                    get: { viewModel.myStatus.statusMessage },
                    set: { viewModel.setMyStatus($0) }
                )) {
                    ForEach(RangerStatus.StatusMessage.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Zone
            if let zone = viewModel.myStatus.currentZone {
                HStack(spacing: DSSpace.xs) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Color.dsPrimary)
                        .font(.system(size: 14))
                    Text(zone)
                        .font(DSFont.callout)
                        .foregroundStyle(Color.dsInk2)
                }
            }
        }
        .dsCard()
    }

    // MARK: - Assistance Button

    private var assistanceButton: some View {
        Button {
            viewModel.setMyStatus(.needAssistance)
        } label: {
            HStack(spacing: DSSpace.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .bold))
                Text("Need Assistance")
                    .font(DSFont.subhead)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpace.md)
            .background(
                viewModel.myStatus.statusMessage == .needAssistance
                    ? Color.dsStatusActive
                    : Color.dsStatusActive.opacity(0.85)
            )
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
            .shadow(
                color: Color.dsStatusActive.opacity(
                    viewModel.myStatus.statusMessage == .needAssistance ? 0.45 : 0.2
                ),
                radius: 8, x: 0, y: 4
            )
            .scaleEffect(viewModel.myStatus.statusMessage == .needAssistance ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: viewModel.myStatus.statusMessage)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Nearby Rangers List

    @ViewBuilder
    private var nearbyRangersList: some View {
        VStack(alignment: .leading, spacing: DSSpace.md) {
            HStack(spacing: DSSpace.sm) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dsPrimary)
                Text("Nearby Rangers")
                    .font(DSFont.headline)
                    .foregroundStyle(Color.dsInk)
                Spacer()
                Text("\(viewModel.nearbyRangers.count)")
                    .font(DSFont.badge)
                    .foregroundStyle(Color.dsPrimary)
                    .padding(.horizontal, DSSpace.sm)
                    .padding(.vertical, DSSpace.xs)
                    .background(Color.dsPrimarySoft)
                    .clipShape(Capsule())
            }

            if viewModel.nearbyRangers.isEmpty {
                VStack(spacing: DSSpace.sm) {
                    Image(systemName: "personalhotspot.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.dsInkMuted)
                    Text("No rangers in range")
                        .font(DSFont.callout)
                        .foregroundStyle(Color.dsInk3)
                    Text("Rangers who broadcast nearby will appear here.")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.dsInkMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DSSpace.xl)
            } else {
                VStack(spacing: DSSpace.sm) {
                    ForEach(viewModel.nearbyRangers) { ranger in
                        RangerStatusRow(ranger: ranger)
                    }
                }
            }
        }
        .dsCard()
    }

    // MARK: - Battery indicator

    @ViewBuilder
    private func batteryIndicator(_ level: Float) -> some View {
        HStack(spacing: 3) {
            Image(systemName: batteryIcon(level))
                .foregroundStyle(batteryColor(level))
                .font(.system(size: 14))
            Text("\(Int(level * 100))%")
                .font(DSFont.caption)
                .foregroundStyle(Color.dsInk3)
        }
    }

    private func batteryIcon(_ level: Float) -> String {
        switch level {
        case 0.75...: return "battery.100"
        case 0.50...: return "battery.75"
        case 0.25...: return "battery.50"
        default:      return "battery.25"
        }
    }

    private func batteryColor(_ level: Float) -> Color {
        level < 0.2 ? Color.dsStatusActive : Color.dsStatusCleared
    }
}

// MARK: - RangerStatusRow

private struct RangerStatusRow: View {
    let ranger: RangerStatus

    private var secondsSinceLastSeen: TimeInterval {
        Date().timeIntervalSince(ranger.lastSeen)
    }

    private var presenceDotColor: Color {
        switch secondsSinceLastSeen {
        case ..<120:   return Color.dsStatusCleared   // < 2 min — green
        case ..<300:   return Color.dsStatusTreat     // 2-5 min — amber
        default:       return Color.dsInkMuted        // > 5 min — grey
        }
    }

    private var timeAgoText: String {
        let mins = Int(secondsSinceLastSeen / 60)
        if mins < 1 { return "just now" }
        return "\(mins)m ago"
    }

    private var statusColor: Color {
        ranger.statusMessage == .needAssistance ? Color.dsStatusActive : Color.dsInk2
    }

    var body: some View {
        HStack(alignment: .center, spacing: DSSpace.sm) {
            // Presence dot
            Circle()
                .fill(presenceDotColor)
                .frame(width: 10, height: 10)

            // Name + zone
            VStack(alignment: .leading, spacing: 2) {
                Text(ranger.rangerName)
                    .font(DSFont.callout)
                    .foregroundStyle(Color.dsInk)
                if let zone = ranger.currentZone {
                    Text(zone)
                        .font(DSFont.caption)
                        .foregroundStyle(Color.dsInk3)
                }
            }

            Spacer()

            // Status + time
            VStack(alignment: .trailing, spacing: 2) {
                Text(ranger.statusMessage.rawValue)
                    .font(DSFont.badge)
                    .foregroundStyle(statusColor)
                Text(timeAgoText)
                    .font(DSFont.caption)
                    .foregroundStyle(Color.dsInkMuted)
            }
        }
        .padding(DSSpace.sm)
        .background(Color.dsSurface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
    }
}
