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

    private var firstName: String {
        appEnv.authManager.currentRanger?.displayName?
            .components(separatedBy: " ").first ?? "Ranger"
    }

    private var seasonLabel: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 11, 12, 1, 2, 3: return "WET SEASON"
        case 4, 5, 6:          return "TRANSITION"
        default:               return "DRY SEASON"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    headerSection
                    chartCard
                    zoneAndStatRow
                    recentSightingsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color.paper.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear { viewModel.load() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("GATHER · \(seasonLabel)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.bark)
                .kerning(1.4)
            Text("G'day, \(firstName).")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.ink)
                .kerning(-0.7)
            Text("5 rangers on country · offline mode")
                .font(.system(size: 14))
                .foregroundColor(Color.ink3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 54)
        .padding(.bottom, 8)
    }

    // MARK: - Sightings line chart card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Sightings by variant")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.ink)
                Spacer()
                Text("last 6 months")
                    .font(.system(size: 11))
                    .foregroundColor(Color.ink3)
            }

            let variantSeries = groupedVariantSeries()

            Chart {
                ForEach(variantSeries, id: \.variantName) { series in
                    ForEach(series.points, id: \.date) { point in
                        LineMark(
                            x: .value("Month", point.date),
                            y: .value("Count", point.count)
                        )
                        .foregroundStyle(series.color)
                        .lineStyle(StrokeStyle(lineWidth: 1.8))
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Month", point.date),
                            y: .value("Count", point.count)
                        )
                        .foregroundStyle(series.color)
                        .symbolSize(24)
                    }
                }
            }
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) {
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.ink3)
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.lineBase.opacity(0.1))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) {
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Color.ink3)
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.lineBase.opacity(0.1))
                }
            }
            .frame(height: 130)

            chartLegend(variantSeries)
        }
        .dsCard(padding: 14)
    }

    private func chartLegend(_ series: [VariantSeries]) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(series, id: \.variantName) { s in
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(s.color)
                        .frame(width: 14, height: 2.5)
                    Text(s.variantName)
                        .font(.system(size: 11))
                        .foregroundColor(Color.ink2)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: - Zone donut + stat cards row

    private var zoneAndStatRow: some View {
        HStack(alignment: .top, spacing: 12) {
            zoneDonutCard
                .frame(width: 158)
            VStack(spacing: 12) {
                openTasksCard
                treatmentsCard
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var zoneDonutCard: some View {
        let active   = viewModel.zoneStatusCounts["active"] ?? 0
        let treating = viewModel.zoneStatusCounts["underTreatment"] ?? 0
        let cleared  = viewModel.zoneStatusCounts["cleared"] ?? 0
        let total    = active + treating + cleared

        let sectors: [(label: String, count: Int, color: Color)] = [
            ("Active",    active,   Color.statusActive),
            ("Treating",  treating, Color.statusTreat),
            ("Cleared",   cleared,  Color.statusCleared)
        ]

        return VStack(alignment: .leading, spacing: 10) {
            Text("Zone status")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.ink)

            ZStack {
                Chart(sectors, id: \.label) { sector in
                    SectorMark(
                        angle: .value("Count", max(sector.count, total == 0 ? 1 : 0)),
                        innerRadius: .ratio(0.618),
                        angularInset: 2
                    )
                    .foregroundStyle(sector.color)
                }
                .frame(width: 118, height: 118)

                VStack(spacing: 1) {
                    Text("\(total)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color.ink)
                    Text("zones")
                        .font(.system(size: 10))
                        .foregroundColor(Color.ink3)
                }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 5) {
                ForEach(sectors, id: \.label) { sector in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(sector.color)
                            .frame(width: 8, height: 8)
                        Text(sector.label)
                            .font(.system(size: 11))
                            .foregroundColor(Color.ink2)
                        Spacer(minLength: 0)
                        Text("\(sector.count)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.ink)
                    }
                }
            }
        }
        .dsCard(padding: 14)
    }

    private var openTasksCard: some View {
        NavigationLink(destination: EmptyView()) {
            VStack(alignment: .leading, spacing: 3) {
                Text("OPEN TASKS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.ink3)
                    .kerning(0.5)
                Text("\(viewModel.openFollowUpTasks)")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(Color.euc)
                Text("follow-ups pending")
                    .font(.system(size: 11))
                    .foregroundColor(Color.ink3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsCard(padding: 12)
        }
        .buttonStyle(.plain)
    }

    private var treatmentsCard: some View {
        let shortMonth = Calendar.current.shortMonthSymbols[Calendar.current.component(.month, from: Date()) - 1]
        return VStack(alignment: .leading, spacing: 3) {
            Text("TREATMENTS · \(shortMonth.uppercased())")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.ink3)
                .kerning(0.5)
            Text("\(viewModel.treatmentsThisMonth)")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(Color.ochre)
            Text("this month")
                .font(.system(size: 11))
                .foregroundColor(Color.ink3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard(padding: 12)
    }

    // MARK: - Recent sightings

    private var recentSightingsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recent sightings")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.ink)
                Spacer()
                Button("See all") {}
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.ochre)
            }
            .padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.recentSightings.enumerated()), id: \.element.id) { index, sighting in
                    if index > 0 {
                        Divider()
                            .overlay(Color.lineBase.opacity(0.1))
                    }
                    recentSightingRow(sighting)
                }
            }
            .dsCard(padding: 0)
        }
    }

    private func recentSightingRow(_ sighting: DashboardViewModel.RecentSighting) -> some View {
        let variant = LantanaVariant(rawValue: sighting.variantRaw) ?? .unknown
        let syncKind: SyncStatusKind = sighting.syncStatus == 3 ? .synced : .pending

        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(variant.color.opacity(0.9))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(variant.displayName + (sighting.zoneName.map { " · \($0)" } ?? ""))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.ink)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if let name = sighting.rangerName {
                        Text(name)
                    }
                    if let date = sighting.createdAt {
                        Text("·")
                        Text(date, style: .relative) + Text(" ago")
                    }
                    if let size = sighting.infestationSize {
                        Text("·")
                        Text(size)
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(Color.ink3)
                .lineLimit(1)
            }

            Spacer(minLength: 0)

            SyncBadge(status: syncKind)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }

    // MARK: - Helpers

    private struct VariantSeries {
        let variantName: String
        let color: Color
        let points: [(date: Date, count: Int)]
    }

    private func groupedVariantSeries() -> [VariantSeries] {
        var byVariant: [String: [(date: Date, count: Int)]] = [:]
        for entry in viewModel.monthlySightingData {
            byVariant[entry.variant, default: []].append((date: entry.date, count: entry.count))
        }
        return byVariant.map { name, points in
            let color = LantanaVariant.allCases
                .first(where: { $0.displayName == name })?.color ?? .gray
            return VariantSeries(
                variantName: name,
                color: color,
                points: points.sorted { $0.date < $1.date }
            )
        }
        .sorted { $0.variantName < $1.variantName }
    }

}

