import SwiftUI

struct ActivePatrolView: View {
    @ObservedObject var viewModel: PatrolViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: DSSpace.sm) {
                Text(viewModel.activePatrol?.areaName ?? "Active Patrol")
                    .font(DSFont.title)
                    .foregroundStyle(Color.dsInk)
                ProgressView(value: viewModel.completionPercentage)
                    .tint(Color.dsPrimary)
                Text("\(Int(viewModel.completionPercentage * 100))% complete")
                    .font(DSFont.caption)
                    .foregroundStyle(Color.dsInk3)
            }
            .padding(DSSpace.lg)
            .background(Color.dsSurface)

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
            }, color: Color.dsPrimary)
            .padding()
        }
    }
}

struct ChecklistItemRow: View {
    let item: PatrolChecklistItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: DSSpace.md) {
                Image(systemName: item.isComplete ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundStyle(item.isComplete ? Color.dsPrimary : Color.dsInk3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.label)
                        .font(DSFont.body)
                        .strikethrough(item.isComplete)
                        .foregroundStyle(item.isComplete ? Color.dsInk3 : Color.dsInk)
                    if let time = item.completedAt {
                        Text(time, style: .time)
                            .font(DSFont.caption)
                            .foregroundStyle(Color.dsInk3)
                    }
                }
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}
