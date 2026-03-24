import SwiftUI

struct PatrolListView: View {
    let patrols: [PatrolRecord]

    var body: some View {
        List(patrols, id: \.id) { patrol in
            PatrolListRow(patrol: patrol)
        }
        .listStyle(.plain)
    }
}

struct PatrolListRow: View {
    let patrol: PatrolRecord

    private var isComplete: Bool { patrol.endTime != nil }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle.dotted")
                .foregroundColor(isComplete ? .green : .orange)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(patrol.areaName ?? "Unknown Area")
                    .font(.headline)
                if let date = patrol.patrolDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if isComplete {
                Text("Done")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            } else {
                Text("Active")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}
