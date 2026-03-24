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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Sync status
                    if viewModel.pendingSyncCount > 0 {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.orange)
                            Text("\(viewModel.pendingSyncCount) records pending sync")
                                .font(.callout)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                    }

                    // Stat cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Total\nSightings", value: "\(viewModel.totalSightings)", color: .red)
                        StatCard(title: "This\nMonth", value: "\(viewModel.sightingsThisMonth)", color: .orange)
                        StatCard(title: "Treatments\nThis Month", value: "\(viewModel.treatmentsThisMonth)", color: .blue)
                    }

                    // Zone status doughnut
                    if !viewModel.zoneStatusCounts.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Zones by Status")
                                .font(.headline)
                            Chart(Array(viewModel.zoneStatusCounts), id: \.key) { key, value in
                                SectorMark(
                                    angle: .value("Count", value),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(zoneStatusColor(key))
                                .annotation(position: .overlay) {
                                    Text("\(value)").font(.caption.bold()).foregroundColor(.white)
                                }
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Monthly sightings line chart
                    VStack(alignment: .leading) {
                        Text("Sightings per Month")
                            .font(.headline)
                        Chart(viewModel.monthlySightingData, id: \.date) { entry in
                            LineMark(
                                x: .value("Month", entry.date),
                                y: .value("Count", entry.count)
                            )
                            .foregroundStyle(by: .value("Variant", entry.variant))
                        }
                        .frame(height: 180)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) {
                                AxisValueLabel(format: .dateTime.month(.abbreviated))
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Last sync
                    if let lastSync = viewModel.lastSyncDate {
                        HStack {
                            Image(systemName: "checkmark.icloud.fill")
                                .foregroundColor(.green)
                            Text("Last synced: ")
                            Text(lastSync, style: .relative)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .onAppear { viewModel.load() }
        }
    }

    private func zoneStatusColor(_ status: String) -> Color {
        switch status {
        case "active": return .red
        case "underTreatment": return .orange
        case "cleared": return .green
        default: return .gray
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title.bold())
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
