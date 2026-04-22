import SwiftUI

struct AddMaintenanceRecordView: View {
    let item: Equipment
    @ObservedObject var viewModel: EquipmentViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: MaintenanceType = .routineService
    @State private var descriptionText: String = ""
    @State private var performedBy: String = ""
    @State private var costText: String = ""
    @State private var hasCost: Bool = false

    enum MaintenanceType: String, CaseIterable, Identifiable {
        case routineService    = "Routine Service"
        case repair            = "Repair"
        case inspection        = "Inspection"
        case cleaning          = "Cleaning"
        case partsReplacement  = "Parts Replacement"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .routineService:   return "wrench.and.screwdriver.fill"
            case .repair:           return "hammer.fill"
            case .inspection:       return "magnifyingglass"
            case .cleaning:         return "sparkles"
            case .partsReplacement: return "arrow.triangle.2.circlepath"
            }
        }
    }

    private var parsedCost: Double? {
        guard hasCost else { return nil }
        return Double(costText.trimmingCharacters(in: .whitespaces))
    }

    private var canSave: Bool {
        !descriptionText.trimmingCharacters(in: .whitespaces).isEmpty &&
        !performedBy.trimmingCharacters(in: .whitespaces).isEmpty &&
        (!hasCost || parsedCost != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $selectedType) {
                        ForEach(MaintenanceType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(DSFont.body)
                } header: {
                    Text("Maintenance Type")
                        .font(DSFont.callout)
                }

                Section {
                    TextField("Describe the work done", text: $descriptionText, axis: .vertical)
                        .font(DSFont.body)
                        .lineLimit(3...6)
                } header: {
                    Text("Description")
                        .font(DSFont.callout)
                }

                Section {
                    TextField("Ranger or technician name", text: $performedBy)
                        .font(DSFont.body)
                } header: {
                    Text("Performed By")
                        .font(DSFont.callout)
                }

                Section {
                    Toggle("Record cost", isOn: $hasCost.animation())
                        .font(DSFont.body)
                        .tint(Color.dsPrimary)
                    if hasCost {
                        HStack {
                            Text("$")
                                .font(DSFont.body)
                                .foregroundStyle(Color.dsInk3)
                            TextField("0.00", text: $costText)
                                .keyboardType(.decimalPad)
                                .font(DSFont.body)
                        }
                    }
                } header: {
                    Text("Cost")
                        .font(DSFont.callout)
                }

                Section {
                    HStack(spacing: DSSpace.sm) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color.dsInk3)
                            .font(.system(size: 13))
                        Text("Logging maintenance will set next service due in 90 days.")
                            .font(DSFont.footnote)
                            .foregroundStyle(Color.dsInk3)
                    }
                    .padding(.vertical, DSSpace.xs)
                }
            }
            .navigationTitle("Log Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.logMaintenance(
                            for: item,
                            type: selectedType.rawValue,
                            description: descriptionText.trimmingCharacters(in: .whitespaces),
                            performedBy: performedBy.trimmingCharacters(in: .whitespaces),
                            cost: parsedCost
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                    .font(DSFont.subhead)
                }
            }
        }
    }
}
