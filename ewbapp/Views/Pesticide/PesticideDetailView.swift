import SwiftUI

struct PesticideDetailView: View {
    let stock: PesticideStock
    @ObservedObject var viewModel: PesticideViewModel
    @State private var showLogUsage = false
    @EnvironmentObject var appEnv: AppEnvironment

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Summary card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(String(format: "%.1f %@", stock.currentQuantity, stock.unit ?? "L"))
                            .font(.title.bold())
                            .foregroundColor(stock.currentQuantity <= stock.minThreshold ? .red : .primary)
                        Spacer()
                        Text("Min: \(String(format: "%.1f", stock.minThreshold)) \(stock.unit ?? "L")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if stock.currentQuantity <= stock.minThreshold {
                        Label("Low Stock — reorder required", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                LargeButton(title: "Log Usage", action: { showLogUsage = true })

                // Usage history
                Text("Usage History")
                    .font(.headline)
                let history = viewModel.usageHistory(for: stock)
                if history.isEmpty {
                    Text("No usage recorded yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(history, id: \.id) { record in
                        UsageRow(record: record)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(stock.productName ?? "Product")
        .sheet(isPresented: $showLogUsage, onDismiss: { viewModel.load() }) {
            LogUsageView(stock: stock, viewModel: viewModel, rangerID: appEnv.authManager.currentRangerID ?? UUID())
        }
    }
}

struct UsageRow: View {
    let record: PesticideUsageRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "–%.1f %@", record.usedQuantity, record.stock?.unit ?? "L"))
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
                if let notes = record.notes, !notes.isEmpty {
                    Text(notes).font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            if let date = record.usedAt {
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
