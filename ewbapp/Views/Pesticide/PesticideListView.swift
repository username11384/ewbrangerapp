import SwiftUI

struct PesticideListView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: PesticideViewModel
    @State private var showAddSheet = false
    @State private var expandedIDs: Set<UUID> = []

    init() {
        _viewModel = StateObject(wrappedValue: PesticideViewModel(
            persistence: AppEnvironment.shared.persistence
        ))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("Pesticide inventory")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.ink)
                    Spacer()
                }
                .padding(.top, 54)
                .padding(.bottom, 16)
                .padding(.horizontal, 16)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.stocks, id: \.id) { stock in
                            let isExpanded = expandedIDs.contains(stock.id ?? UUID())
                            PesticideCard(
                                stock: stock,
                                viewModel: viewModel,
                                isExpanded: isExpanded,
                                onToggleExpand: {
                                    let id = stock.id ?? UUID()
                                    if expandedIDs.contains(id) {
                                        expandedIDs.remove(id)
                                    } else {
                                        expandedIDs.insert(id)
                                    }
                                },
                                rangerID: appEnv.authManager.currentRangerID ?? UUID()
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.ink)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 58)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showAddSheet, onDismiss: { viewModel.load() }) {
            AddStockView(viewModel: viewModel)
        }
        .onAppear { viewModel.load() }
    }
}

private struct PesticideCard: View {
    let stock: PesticideStock
    @ObservedObject var viewModel: PesticideViewModel
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let rangerID: UUID

    @State private var showLogUsage = false
    @EnvironmentObject var appEnv: AppEnvironment

    private enum StockLevel { case low, gettingLow, normal }

    private var stockLevel: StockLevel {
        let qty = stock.currentQuantity
        let threshold = stock.minThreshold
        if qty <= threshold { return .low }
        if qty <= threshold * 1.75 { return .gettingLow }
        return .normal
    }

    private var totalEstimate: Double {
        max(stock.minThreshold * 5, stock.currentQuantity)
    }

    private var fillFraction: Double {
        guard totalEstimate > 0 else { return 0 }
        return min(stock.currentQuantity / totalEstimate, 1.0)
    }

    private var iconBg: Color {
        switch stockLevel {
        case .low: return .statusActiveSoft
        case .gettingLow: return .statusTreatSoft
        case .normal: return .eucSoft
        }
    }

    private var iconFg: Color {
        switch stockLevel {
        case .low: return .statusActive
        case .gettingLow: return .statusTreat
        case .normal: return .euc
        }
    }

    private var barColor: Color {
        switch stockLevel {
        case .low: return .statusActive
        case .gettingLow: return .statusTreat
        case .normal: return .euc
        }
    }

    @ViewBuilder private var stockLevelPill: some View {
        switch stockLevel {
        case .low:
            Text("Low")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.statusActive)
                .padding(.vertical, 2)
                .padding(.horizontal, 7)
                .background(Color.statusActiveSoft)
                .clipShape(Capsule())
        case .gettingLow:
            Text("Getting low")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.statusTreat)
                .padding(.vertical, 2)
                .padding(.horizontal, 7)
                .background(Color.statusTreatSoft)
                .clipShape(Capsule())
        case .normal:
            EmptyView()
        }
    }

    private var recentHistory: [PesticideUsageRecord] {
        Array(viewModel.usageHistory(for: stock).prefix(3))
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconBg)
                        .frame(width: 44, height: 44)
                    Image(systemName: "drop.fill")
                        .font(.system(size: 20))
                        .foregroundColor(iconFg)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(stock.productName ?? "Unknown")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.ink)
                        stockLevelPill
                    }
                    Text("Herbicide · \(String(format: "%.1f", stock.currentQuantity)) / \(String(format: "%.1f", totalEstimate)) \(stock.unit ?? "L")")
                        .font(.system(size: 12))
                        .foregroundColor(.ink3)
                }

                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.paperDeep)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(fillFraction), height: 8)
                }
            }
            .frame(height: 8)

            HStack(spacing: 12) {
                Button(action: onToggleExpand) {
                    Text(isExpanded ? "Hide usage log" : "View usage log")
                        .font(.system(size: 13))
                        .foregroundColor(.ink3)
                }

                Spacer()

                Button(action: { showLogUsage = true }) {
                    Text("Log usage")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.euc)
                        .cornerRadius(10)
                }
            }

            if isExpanded {
                Divider()
                    .background(Color.lineBase.opacity(0.12))

                if recentHistory.isEmpty {
                    Text("No usage recorded yet.")
                        .font(.system(size: 13))
                        .foregroundColor(.ink3)
                        .padding(.top, 2)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(recentHistory, id: \.id) { record in
                            HStack(alignment: .top, spacing: 0) {
                                Text(record.usedAt.map { Self.dateFormatter.string(from: $0) } ?? "—")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.ink3)
                                    .frame(width: 58, alignment: .leading)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(record.ranger?.displayName ?? "Ranger")
                                        .font(.system(size: 12))
                                        .foregroundColor(.ink2)
                                    if let notes = record.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.system(size: 11))
                                            .foregroundColor(.ink3)
                                    }
                                }

                                Spacer()

                                Text(String(format: "–%.1f %@", record.usedQuantity, record.stock?.unit ?? "L"))
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.statusActive)
                            }
                        }
                    }
                }
            }
        }
        .dsCard(padding: 14)
        .sheet(isPresented: $showLogUsage, onDismiss: { viewModel.load() }) {
            LogUsageView(stock: stock, viewModel: viewModel, rangerID: rangerID)
        }
    }
}

struct AddStockView: View {
    @ObservedObject var viewModel: PesticideViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var productName = ""
    @State private var unit = "litres"
    @State private var initialQty = ""
    @State private var threshold = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Product Name (e.g. Garlon 600)", text: $productName)
                Picker("Unit", selection: $unit) {
                    Text("Litres").tag("litres")
                    Text("Kilograms").tag("kilograms")
                }
                TextField("Initial Quantity", text: $initialQty)
                    .keyboardType(.decimalPad)
                TextField("Low-Stock Threshold", text: $threshold)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Add Product")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addStock(
                                productName: productName,
                                unit: unit,
                                initialQuantity: Double(initialQty) ?? 0,
                                minThreshold: Double(threshold) ?? 0
                            )
                            dismiss()
                        }
                    }
                    .disabled(productName.isEmpty)
                }
            }
        }
    }
}
