import SwiftUI

struct EquipmentListView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: EquipmentViewModel
    @State private var showAddEquipment = false
    @State private var selectedEquipment: Equipment?

    init() {
        _viewModel = StateObject(wrappedValue: EquipmentViewModel(
            persistence: AppEnvironment.shared.persistence
        ))
    }

    var body: some View {
        Group {
            if viewModel.equipment.isEmpty {
                emptyState
            } else {
                equipmentList
            }
        }
        .navigationTitle("Equipment")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddEquipment = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddEquipment, onDismiss: { viewModel.load() }) {
            AddEquipmentView(viewModel: viewModel)
        }
        .onAppear { viewModel.load() }
    }

    // MARK: - List

    private var equipmentList: some View {
        List {
            // Alert banners
            if !viewModel.overdueItems.isEmpty {
                Section {
                    Label(
                        "\(viewModel.overdueItems.count) item\(viewModel.overdueItems.count == 1 ? "" : "s") overdue for maintenance",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(Color.dsStatusActive)
                    .font(DSFont.subhead)
                }
            } else if !viewModel.dueSoonItems.isEmpty {
                Section {
                    Label(
                        "\(viewModel.dueSoonItems.count) item\(viewModel.dueSoonItems.count == 1 ? "" : "s") due within 14 days",
                        systemImage: "clock.badge.exclamationmark.fill"
                    )
                    .foregroundStyle(Color.dsStatusTreat)
                    .font(DSFont.subhead)
                }
            }

            Section {
                ForEach(viewModel.equipment) { item in
                    NavigationLink(destination: EquipmentDetailView(item: item, viewModel: viewModel)) {
                        EquipmentRow(item: item, viewModel: viewModel)
                    }
                }
                .onDelete { offsets in
                    offsets.map { viewModel.equipment[$0] }.forEach { viewModel.deleteEquipment($0) }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DSSpace.lg) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 52))
                .foregroundStyle(Color.dsInk3)
            Text("No Equipment")
                .font(DSFont.headline)
                .foregroundStyle(Color.dsInk)
            Text("Add equipment to start tracking\nmaintenance schedules.")
                .font(DSFont.body)
                .foregroundStyle(Color.dsInk3)
                .multilineTextAlignment(.center)
            Button {
                showAddEquipment = true
            } label: {
                Text("Add Equipment")
                    .font(DSFont.subhead)
                    .foregroundStyle(.white)
                    .frame(height: 44)
                    .frame(minWidth: 160)
                    .background(Color.dsPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
            }
        }
        .padding(DSSpace.xl)
    }
}

// MARK: - Equipment Row

struct EquipmentRow: View {
    let item: Equipment
    let viewModel: EquipmentViewModel

    private var statusColor: Color {
        let today = Date()
        guard let due = item.nextMaintenanceDue else { return Color.dsInk3 }
        if due < today { return Color.dsStatusActive }
        if let twoWeeks = Calendar.current.date(byAdding: .day, value: 14, to: today), due <= twoWeeks {
            return Color.dsStatusTreat
        }
        return Color.dsStatusCleared
    }

    private var statusLabel: String {
        let today = Date()
        guard let due = item.nextMaintenanceDue else { return "No schedule" }
        if due < today {
            let days = Calendar.current.dateComponents([.day], from: due, to: today).day ?? 0
            return "\(days)d overdue"
        }
        let days = Calendar.current.dateComponents([.day], from: today, to: due).day ?? 0
        if days == 0 { return "Due today" }
        if days == 1 { return "Due tomorrow" }
        return "Due in \(days)d"
    }

    private var typeIcon: String {
        switch item.equipmentType?.lowercased() {
        case "vehicle":       return "car.fill"
        case "sprayer":       return "water.waves"
        case "radio":         return "antenna.radiowaves.left.and.right"
        case "chainsaw":      return "circle.slash"
        case "boat":          return "ferry.fill"
        default:              return "wrench.fill"
        }
    }

    var body: some View {
        HStack(spacing: DSSpace.md) {
            // Status dot
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            // Type icon
            Image(systemName: typeIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.dsPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name ?? "Unnamed")
                    .font(DSFont.subhead)
                    .foregroundStyle(Color.dsInk)

                HStack(spacing: DSSpace.sm) {
                    Text(item.equipmentType ?? "Equipment")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.dsInk3)

                    if let serial = item.serialNumber, !serial.isEmpty {
                        Text("·")
                            .font(DSFont.caption)
                            .foregroundStyle(Color.dsInkMuted)
                        Text(serial)
                            .font(DSFont.mono)
                            .foregroundStyle(Color.dsInk3)
                    }
                }

                Text(statusLabel)
                    .font(DSFont.caption)
                    .foregroundStyle(statusColor)
            }

            Spacer()
        }
        .padding(.vertical, DSSpace.xs)
    }
}

// MARK: - Equipment Detail View

struct EquipmentDetailView: View {
    let item: Equipment
    @ObservedObject var viewModel: EquipmentViewModel
    @State private var showLogMaintenance = false

    private var records: [MaintenanceRecord] {
        viewModel.records(for: item)
    }

    var body: some View {
        List {
            // Equipment info card
            Section {
                InfoRow(label: "Type", value: item.equipmentType ?? "—")
                if let serial = item.serialNumber, !serial.isEmpty {
                    InfoRow(label: "Serial", value: serial)
                }
                if let notes = item.notes, !notes.isEmpty {
                    InfoRow(label: "Notes", value: notes)
                }
                if let last = item.lastMaintenanceDate {
                    InfoRow(label: "Last Service", value: last.formatted(date: .abbreviated, time: .omitted))
                }
                if let next = item.nextMaintenanceDue {
                    InfoRow(label: "Next Due", value: next.formatted(date: .abbreviated, time: .omitted))
                }
            } header: {
                Text("Details")
                    .font(DSFont.callout)
            }

            // Maintenance history
            Section {
                if records.isEmpty {
                    Text("No maintenance records yet.")
                        .font(DSFont.body)
                        .foregroundStyle(Color.dsInkMuted)
                        .padding(.vertical, DSSpace.sm)
                } else {
                    ForEach(records) { record in
                        MaintenanceRecordRow(record: record)
                    }
                }
            } header: {
                Text("Maintenance History")
                    .font(DSFont.callout)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(item.name ?? "Equipment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showLogMaintenance = true
                } label: {
                    Label("Log Service", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showLogMaintenance, onDismiss: { viewModel.load() }) {
            AddMaintenanceRecordView(item: item, viewModel: viewModel)
        }
    }
}

// MARK: - Maintenance Record Row

struct MaintenanceRecordRow: View {
    let record: MaintenanceRecord

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpace.xs) {
            HStack {
                Text(record.maintenanceType)
                    .font(DSFont.subhead)
                    .foregroundStyle(Color.dsInk)
                Spacer()
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(DSFont.caption)
                    .foregroundStyle(Color.dsInk3)
            }
            Text(record.descriptionText)
                .font(DSFont.body)
                .foregroundStyle(Color.dsInk2)
            HStack(spacing: DSSpace.sm) {
                Label(record.performedBy, systemImage: "person.circle")
                    .font(DSFont.caption)
                    .foregroundStyle(Color.dsInk3)
                if record.costAmount > 0 {
                    Text("·")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.dsInkMuted)
                    Text("$\(record.costAmount, specifier: "%.2f")")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.dsInk3)
                }
            }
        }
        .padding(.vertical, DSSpace.xs)
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(DSFont.callout)
                .foregroundStyle(Color.dsInk3)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(DSFont.body)
                .foregroundStyle(Color.dsInk)
            Spacer()
        }
    }
}
