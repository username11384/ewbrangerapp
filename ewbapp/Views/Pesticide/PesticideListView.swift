import SwiftUI

struct PesticideListView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: PesticideViewModel
    @State private var showAddSheet = false

    init() {
        _viewModel = StateObject(wrappedValue: PesticideViewModel(
            persistence: AppEnvironment.shared.persistence
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Low-stock alert banner
                if !viewModel.lowStockItems.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("\(viewModel.lowStockItems.count) product(s) low on stock")
                            .font(.callout)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                }
                List {
                    ForEach(viewModel.stocks, id: \.id) { stock in
                        NavigationLink(destination: PesticideDetailView(stock: stock, viewModel: viewModel)) {
                            StockRow(stock: stock)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Supplies")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddSheet = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAddSheet, onDismiss: { viewModel.load() }) {
                AddStockView(viewModel: viewModel)
            }
            .onAppear { viewModel.load() }
        }
    }
}

struct StockRow: View {
    let stock: PesticideStock

    private var isLow: Bool { stock.currentQuantity <= stock.minThreshold }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.productName ?? "Unknown")
                    .font(.headline)
                Text("\(String(format: "%.1f", stock.currentQuantity)) \(stock.unit ?? "L")")
                    .font(.callout)
                    .foregroundColor(isLow ? .red : .secondary)
            }
            Spacer()
            if isLow {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
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
