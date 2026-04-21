import SwiftUI

struct PesticideDetailView: View {
    let stock: PesticideStock
    @ObservedObject var viewModel: PesticideViewModel
    @State private var showLogUsage = false
    @EnvironmentObject var appEnv: AppEnvironment

    private var isLow: Bool { stock.currentQuantity <= stock.minThreshold }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpace.lg) {
                // Summary card
                VStack(alignment: .leading, spacing: DSSpace.sm) {
                    HStack {
                        Text(String(format: "%.1f %@", stock.currentQuantity, stock.unit ?? "L"))
                            .font(DSFont.title)
                            .foregroundStyle(isLow ? Color.dsStatusActive : Color.dsInk)
                        Spacer()
                        Text("Min: \(String(format: "%.1f", stock.minThreshold)) \(stock.unit ?? "L")")
                            .font(DSFont.caption)
                            .foregroundStyle(Color.dsInk3)
                    }
                    if isLow {
                        HStack(spacing: DSSpace.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Low Stock — reorder required")
                                .font(DSFont.callout)
                        }
                        .foregroundStyle(Color.dsStatusActive)
                        .padding(DSSpace.sm)
                        .background(Color.dsStatusActiveSoft)
                        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                    }
                }
                .dsCard()

                LargeButton(title: "Log Usage", action: { showLogUsage = true })

                // Usage history
                VStack(alignment: .leading, spacing: DSSpace.md) {
                    Text("Usage History")
                        .font(DSFont.headline)
                        .foregroundStyle(Color.dsInk)
                    let history = viewModel.usageHistory(for: stock)
                    if history.isEmpty {
                        Text("No usage recorded yet.")
                            .font(DSFont.body)
                            .foregroundStyle(Color.dsInk3)
                    } else {
                        ForEach(history, id: \.id) { record in
                            UsageRow(record: record)
                        }
                    }
                }
            }
            .padding(DSSpace.lg)
        }
        .background(Color.dsBackground.ignoresSafeArea())
        .navigationTitle(stock.productName ?? "Product")
        .sheet(isPresented: $showLogUsage, onDismiss: { viewModel.load() }) {
            LogUsageView(stock: stock, viewModel: viewModel, rangerID: appEnv.authManager.currentRangerID ?? {
                assertionFailure("PesticideDetailView accessed without authenticated ranger")
                return UUID()
            }())
        }
    }
}

struct UsageRow: View {
    let record: PesticideUsageRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "–%.1f %@", record.usedQuantity, record.stock?.unit ?? "L"))
                    .font(DSFont.callout)
                    .foregroundStyle(Color.dsStatusActive)
                if let notes = record.notes, !notes.isEmpty {
                    Text(notes)
                        .font(DSFont.caption)
                        .foregroundStyle(Color.dsInk3)
                }
            }
            Spacer()
            if let date = record.usedAt {
                Text(date, style: .date)
                    .font(DSFont.caption)
                    .foregroundStyle(Color.dsInk3)
            }
        }
        .padding(DSSpace.sm)
        .background(Color.dsSurface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
    }
}
