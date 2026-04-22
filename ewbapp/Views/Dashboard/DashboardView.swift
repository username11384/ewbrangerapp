import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: DashboardViewModel
    @StateObject private var pesticideViewModel: PesticideViewModel
    @State private var statCardsAppeared = false

    init() {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(
            persistence: AppEnvironment.shared.persistence,
            syncEngine: AppEnvironment.shared.syncEngine
        ))
        _pesticideViewModel = StateObject(wrappedValue: PesticideViewModel(
            persistence: AppEnvironment.shared.persistence
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

                // Stat cards grid — stagger in on appear
                let statCards: [(title: String, value: String, icon: String, accent: Color)] = [
                    ("Total Sightings", "\(viewModel.totalSightings)", "binoculars.fill", Color.dsSpeciesLantana),
                    ("This Month",      "\(viewModel.sightingsThisMonth)", "calendar",       Color.dsPrimary),
                    ("Treatments",      "\(viewModel.treatmentsThisMonth)", "cross.case.fill", Color(hex: "4A90A4")),
                    ("Zones Cleared",   String(format: "%.0f%%", viewModel.clearedZonePercent), "checkmark.circle.fill", Color.dsStatusCleared),
                ]
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpace.md) {
                    ForEach(Array(statCards.enumerated()), id: \.offset) { index, card in
                        DSStatCard(title: card.title, value: card.value, icon: card.icon, accent: card.accent)
                            .opacity(statCardsAppeared ? 1 : 0)
                            .scaleEffect(statCardsAppeared ? 1 : 0.88, anchor: .center)
                            .animation(
                                .spring(response: 0.45, dampingFraction: 0.72)
                                    .delay(Double(index) * 0.07),
                                value: statCardsAppeared
                            )
                    }
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

                // Monthly sightings stacked bar chart
                chartCard(title: "Sightings per Month", icon: "chart.bar.xaxis") {
                    Chart(viewModel.monthlySightingData) { entry in
                        BarMark(
                            x: .value("Month", entry.date, unit: .month),
                            y: .value("Count", entry.count)
                        )
                        .foregroundStyle(by: .value("Species", entry.variant))
                        .cornerRadius(3)
                    }
                    .frame(height: 190)
                    .chartForegroundStyleScale(speciesColorScale)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) {
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                                .font(DSFont.caption)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                                .foregroundStyle(Color.dsDivider)
                            AxisValueLabel()
                                .font(DSFont.caption)
                                .foregroundStyle(Color.dsInk3)
                        }
                    }
                    .chartLegend(position: .bottom, alignment: .leading, spacing: 8) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                            ForEach(InvasiveSpecies.allCases.filter { $0 != .unknown }, id: \.self) { species in
                                HStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(species.color)
                                        .frame(width: 10, height: 10)
                                    Text(species.displayName)
                                        .font(DSFont.caption)
                                        .foregroundStyle(Color.dsInk3)
                                        .lineLimit(1)
                                }
                            }
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
        .onAppear {
            viewModel.load()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) {
                statCardsAppeared = true
            }
        }
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
