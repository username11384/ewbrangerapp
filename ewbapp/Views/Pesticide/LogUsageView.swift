import SwiftUI

struct LogUsageView: View {
    let stock: PesticideStock
    @ObservedObject var viewModel: PesticideViewModel
    let rangerID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var quantityStr = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Usage Details") {
                    HStack {
                        Text("Quantity Used (\(stock.unit ?? "L"))")
                        Spacer()
                        TextField("0.0", text: $quantityStr)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    TextField("Notes (optional)", text: $notes)
                }
                Section("Current Stock") {
                    HStack {
                        Text("Before")
                        Spacer()
                        Text(String(format: "%.1f %@", stock.currentQuantity, stock.unit ?? "L"))
                            .foregroundColor(.secondary)
                    }
                    if let qty = Double(quantityStr), qty > 0 {
                        HStack {
                            Text("After")
                            Spacer()
                            Text(String(format: "%.1f %@", max(0, stock.currentQuantity - qty), stock.unit ?? "L"))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Log Usage")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let qty = Double(quantityStr), qty > 0 else { return }
                        Task {
                            await viewModel.logUsage(
                                for: stock,
                                quantity: qty,
                                notes: notes.isEmpty ? nil : notes,
                                rangerID: rangerID
                            )
                            dismiss()
                        }
                    }
                    .disabled(Double(quantityStr) == nil || (Double(quantityStr) ?? 0) <= 0)
                }
            }
        }
    }
}
