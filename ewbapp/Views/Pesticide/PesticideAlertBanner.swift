import SwiftUI

/// Compact banner surfaced on the Dashboard when pesticide stocks are low or critical.
/// Taps expand to reveal per-item rows with a Restock action.
struct PesticideAlertBanner: View {
    @ObservedObject var viewModel: PesticideViewModel
    @State private var isExpanded = false
    @State private var restockingID: UUID?

    private var criticalCount: Int { viewModel.criticalStockItems.count }
    private var lowCount: Int { viewModel.lowStockItems.count }

    // Items to show: critical first, then the remaining low-stock items
    private var displayItems: [PesticideStock] {
        let criticalIDs = Set(viewModel.criticalStockItems.compactMap { $0.id })
        let nonCriticalLow = viewModel.lowStockItems.filter { !criticalIDs.contains($0.id ?? UUID()) }
        return viewModel.criticalStockItems + nonCriticalLow
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row — always visible
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: DSSpace.sm) {
                    Image(systemName: criticalCount > 0 ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(criticalCount > 0 ? Color.dsStatusActive : Color.dsStatusTreat)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(headerTitle)
                            .font(DSFont.callout)
                            .foregroundStyle(Color.dsInk)
                        if criticalCount > 0 && lowCount > criticalCount {
                            Text("\(criticalCount) critical · \(lowCount - criticalCount) low")
                                .font(DSFont.caption)
                                .foregroundStyle(Color.dsInk3)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.dsInk3)
                }
                .padding(DSSpace.md)
                .background(bannerBackgroundColor)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: isExpanded ? DSRadius.lg : DSRadius.lg,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)

            // Expandable item list
            if isExpanded {
                VStack(spacing: DSSpace.xs) {
                    ForEach(displayItems, id: \.id) { stock in
                        StockAlertRow(
                            stock: stock,
                            isCritical: viewModel.criticalStockItems.contains(where: { $0.id == stock.id }),
                            isRestocking: restockingID == stock.id,
                            onRestock: {
                                Task {
                                    restockingID = stock.id
                                    // Restock to twice the minimum threshold as a sensible default
                                    let refillAmount = max(stock.minThreshold * 2 - stock.currentQuantity, stock.minThreshold)
                                    await viewModel.restock(stock, volumeLitres: refillAmount)
                                    restockingID = nil
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, DSSpace.md)
                .padding(.bottom, DSSpace.md)
                .background(Color.dsCard)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: DSRadius.lg,
                        bottomTrailingRadius: DSRadius.lg,
                        topTrailingRadius: 0,
                        style: .continuous
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous)
                        .strokeBorder(Color.dsDivider.opacity(0.6), lineWidth: 0.75)
                )
                .shadow(color: Color.dsInk.opacity(0.05), radius: 4, x: 0, y: 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var headerTitle: String {
        if criticalCount > 0 {
            return criticalCount == 1
                ? "1 product critically low"
                : "\(criticalCount) products critically low"
        } else {
            return lowCount == 1
                ? "1 product low on stock"
                : "\(lowCount) products low on stock"
        }
    }

    private var bannerBackgroundColor: Color {
        criticalCount > 0 ? Color.dsStatusActiveSoft : Color.dsStatusTreatSoft
    }
}

// MARK: - Per-item row inside the expanded banner

private struct StockAlertRow: View {
    let stock: PesticideStock
    let isCritical: Bool
    let isRestocking: Bool
    let onRestock: () -> Void

    var body: some View {
        HStack(spacing: DSSpace.sm) {
            // Severity indicator dot
            Circle()
                .fill(isCritical ? Color.dsStatusActive : Color.dsStatusTreat)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(stock.productName ?? "Unknown")
                    .font(DSFont.callout)
                    .foregroundStyle(Color.dsInk)
                Text(
                    "\(String(format: "%.1f", stock.currentQuantity)) / \(String(format: "%.1f", stock.minThreshold)) \(stock.unit ?? "L")"
                )
                .font(DSFont.caption)
                .foregroundStyle(Color.dsInk3)
            }

            Spacer()

            Button(action: onRestock) {
                if isRestocking {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.75)
                        .frame(width: 64, height: 28)
                } else {
                    Text("Restock")
                        .font(DSFont.badge)
                        .foregroundStyle(Color.dsPrimary)
                        .padding(.horizontal, DSSpace.sm)
                        .padding(.vertical, DSSpace.xs)
                        .background(Color.dsPrimarySoft)
                        .clipShape(Capsule())
                }
            }
            .buttonStyle(.plain)
            .disabled(isRestocking)
        }
        .padding(.vertical, DSSpace.sm)
        .padding(.horizontal, DSSpace.sm)
        .background(Color.dsSurface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
    }
}
