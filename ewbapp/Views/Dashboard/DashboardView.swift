import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: DashboardViewModel

    init() {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(
            persistence: AppEnvironment.shared.persistence,
            syncEngine: AppEnvironment.shared.syncEngine
        ))
    }

    // Build species color scale from all InvasiveSpecies cases
    private var speciesColorScale: KeyValuePairs<String, Color> {
        [
            InvasiveSpecies.lantana.displayName:           InvasiveSpecies.lantana.color,
            InvasiveSpecies.rubberVine.displayName:        InvasiveSpecies.rubberVine.color,
            InvasiveSpecies.pricklyAcacia.displayName:     InvasiveSpecies.pricklyAcacia.color,
            InvasiveSpecies.sicklepod.displayName:         InvasiveSpecies.sicklepod.color,
            InvasiveSpecies.giantRatsTailGrass.displayName: InvasiveSpecies.giantRatsTailGrass.color,
            InvasiveSpecies.pondApple.displayName:         InvasiveSpecies.pondApple.color,
            InvasiveSpecies.unknown.displayName:           InvasiveSpecies.unknown.color,
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpace.lg) {

                // Pending sync banner
                if viewModel.pendingSyncCount > 0 {
                    HStack(spacing: DSSpace.sm) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(Color.dsStatusTreat)
                        Text("\(viewModel.pendingSyncCount) records pending sync")
                            .font(DSFont.callout)
                            .foregroundStyle(Color.dsInk2)
                        Spacer()
                    }
                    .padding(DSSpace.md)
                    .background(Color.dsStatusTreatSoft)
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                }

                // Stat cards grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpace.md) {
                    DSStatCard(title: "Total Sightings", value: "\(viewModel.totalSightings)",
                               icon: "binoculars.fill", accent: Color.dsSpeciesLantana)
                    DSStatCard(title: "This Month", value: "\(viewModel.sightingsThisMonth)",
                               icon: "calendar", accent: Color.dsPrimary)
                    DSStatCard(title: "Treatments", value: "\(viewModel.treatmentsThisMonth)",
                               icon: "cross.case.fill", accent: Color(hex: "4A90A4"))
                    DSStatCard(title: "Zones Cleared", value: String(format: "%.0f%%", viewModel.clearedZonePercent),
                               icon: "checkmark.circle.fill", accent: Color.dsStatusCleared)
                }

                if viewModel.openFollowUpTasks > 0 {
                    HStack(spacing: DSSpace.sm) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(Color.dsStatusTreat)
                        Text("\(viewModel.openFollowUpTasks) open follow-up tasks")
                            .font(DSFont.callout)
                            .foregroundStyle(Color.dsInk2)
                        Spacer()
                    }
                    .dsCard(padding: DSSpace.md)
                }

                // Zone status chart
                if !viewModel.zoneStatusCounts.isEmpty {
                    chartCard(title: "Zones by Status", icon: "square.dashed") {
                        Chart(Array(viewModel.zoneStatusCounts), id: \.key) { key, value in
                            SectorMark(
                                angle: .value("Count", value),
                                innerRadius: .ratio(0.52)
                            )
                            .foregroundStyle(zoneStatusColor(key))
                            .annotation(position: .overlay) {
                                if value > 0 {
                                    Text("\(value)")
                                        .font(DSFont.badge)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .frame(height: 180)

                        // Legend
                        HStack(spacing: DSSpace.lg) {
                            ForEach(["active", "underTreatment", "cleared"], id: \.self) { status in
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(zoneStatusColor(status))
                                        .frame(width: 8, height: 8)
                                    Text(statusLabel(status))
                                        .font(DSFont.caption)
                                        .foregroundStyle(Color.dsInk3)
                                }
                            }
                        }
                    }
                }

                // Monthly sightings line chart
                chartCard(title: "Sightings per Month", icon: "chart.line.uptrend.xyaxis") {
                    Chart(viewModel.monthlySightingData, id: \.date) { entry in
                        LineMark(
                            x: .value("Month", entry.date),
                            y: .value("Count", entry.count)
                        )
                        .foregroundStyle(by: .value("Species", entry.variant))
                        PointMark(
                            x: .value("Month", entry.date),
                            y: .value("Count", entry.count)
                        )
                        .foregroundStyle(by: .value("Species", entry.variant))
                        .symbolSize(30)
                    }
                    .frame(height: 160)
                    .chartForegroundStyleScale(speciesColorScale)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) {
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                                .font(DSFont.caption)
                        }
                    }
                }

                // Per-ranger breakdown
                if !viewModel.rangerSightingCounts.isEmpty {
                    chartCard(title: "Sightings by Ranger", icon: "person.2.fill") {
                        VStack(spacing: DSSpace.sm) {
                            ForEach(viewModel.rangerSightingCounts, id: \.name) { entry in
                                HStack(spacing: DSSpace.sm) {
                                    Text(entry.name.components(separatedBy: " ").first ?? entry.name)
                                        .font(DSFont.callout)
                                        .foregroundStyle(Color.dsInk)
                                        .frame(width: 60, alignment: .leading)
                                    GeometryReader { geo in
                                        let maxCount = viewModel.rangerSightingCounts.first?.count ?? 1
                                        let fraction = CGFloat(entry.count) / CGFloat(max(maxCount, 1))
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color.dsSurface)
                                                .frame(height: 8)
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color.dsPrimary.opacity(0.7))
                                                .frame(width: max(geo.size.width * fraction, 4), height: 8)
                                        }
                                    }
                                    .frame(height: 8)
                                    Text("\(entry.count)")
                                        .font(DSFont.badge)
                                        .foregroundStyle(Color.dsInk3)
                                        .frame(width: 28, alignment: .trailing)
                                }
                            }
                        }
                    }
                }

                // Last sync
                if let lastSync = viewModel.lastSyncDate {
                    HStack(spacing: DSSpace.sm) {
                        Image(systemName: "checkmark.icloud.fill")
                            .foregroundStyle(Color.dsSynced)
                        Text("Last synced")
                            .font(DSFont.caption)
                            .foregroundStyle(Color.dsInk3)
                        Text(lastSync, style: .relative)
                            .font(DSFont.caption)
                            .foregroundStyle(Color.dsInk3)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, DSSpace.lg)
            .padding(.vertical, DSSpace.lg)
        }
        .background(Color.dsBackground.ignoresSafeArea())
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { viewModel.load() }
    }

    @ViewBuilder
    private func chartCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DSSpace.md) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dsPrimary)
                Text(title)
                    .font(DSFont.headline)
                    .foregroundStyle(Color.dsInk)
            }
            content()
        }
        .dsCard()
    }

    private func zoneStatusColor(_ status: String) -> Color {
        switch status {
        case "active":         return .dsStatusActive
        case "underTreatment": return .dsStatusTreat
        case "cleared":        return .dsStatusCleared
        default:               return .dsInkMuted
        }
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "underTreatment": return "Treating"
        case "cleared":        return "Cleared"
        default:               return "Active"
        }
    }
}
