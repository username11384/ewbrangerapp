import SwiftUI

struct ActivePatrolView: View {
    @ObservedObject var viewModel: PatrolViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text(viewModel.activePatrol?.areaName ?? "Active Patrol")
                    .font(.title2.bold())
                ProgressView(value: viewModel.completionPercentage)
                    .tint(.green)
                Text("\(Int(viewModel.completionPercentage * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))

            // Checklist
            List {
                ForEach(viewModel.activeChecklistItems) { item in
                    ChecklistItemRow(item: item) {
                        Task { await viewModel.toggleItem(item) }
                    }
                }
            }
            .listStyle(.plain)

            // Finish button
            LargeButton(title: "Finish Patrol", action: {
                Task { await viewModel.finishPatrol() }
            }, color: .blue)
            .padding()
        }
    }
}

struct ChecklistItemRow: View {
    let item: PatrolChecklistItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                Image(systemName: item.isComplete ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(item.isComplete ? .green : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.label)
                        .font(.body)
                        .strikethrough(item.isComplete)
                        .foregroundColor(item.isComplete ? .secondary : .primary)
                    if let time = item.completedAt {
                        Text(time, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}
