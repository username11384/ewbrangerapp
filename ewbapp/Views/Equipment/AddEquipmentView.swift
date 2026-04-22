import SwiftUI

struct AddEquipmentView: View {
    @ObservedObject var viewModel: EquipmentViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedType: EquipmentType = .vehicle
    @State private var serial: String = ""
    @State private var notes: String = ""

    enum EquipmentType: String, CaseIterable, Identifiable {
        case vehicle    = "Vehicle"
        case sprayer    = "Sprayer"
        case radio      = "Radio"
        case chainsaw   = "Chainsaw"
        case boat       = "Boat"
        case other      = "Other"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .vehicle:  return "car.fill"
            case .sprayer:  return "water.waves"
            case .radio:    return "antenna.radiowaves.left.and.right"
            case .chainsaw: return "circle.slash"
            case .boat:     return "ferry.fill"
            case .other:    return "wrench.fill"
            }
        }
    }

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Equipment name", text: $name)
                        .font(DSFont.body)
                } header: {
                    Text("Name")
                        .font(DSFont.callout)
                }

                Section {
                    Picker("Type", selection: $selectedType) {
                        ForEach(EquipmentType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(DSFont.body)
                } header: {
                    Text("Type")
                        .font(DSFont.callout)
                }

                Section {
                    TextField("Serial number (optional)", text: $serial)
                        .font(DSFont.mono)
                } header: {
                    Text("Serial Number")
                        .font(DSFont.callout)
                }

                Section {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .font(DSFont.body)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                        .font(DSFont.callout)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.dsBackground)
            .navigationTitle("Add Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addEquipment(
                            name: name.trimmingCharacters(in: .whitespaces),
                            type: selectedType.rawValue,
                            serial: serial.isEmpty ? nil : serial,
                            notes: notes.isEmpty ? nil : notes
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                    .font(DSFont.subhead)
                }
            }
        }
        .background(Color.dsBackground.ignoresSafeArea())
    }
}
