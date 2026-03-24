import SwiftUI

// MARK: - Calendar Grid

struct PatrolCalendarView: View {
    let patrols: [PatrolRecord]
    @State private var displayMonth: Date = {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
    }()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        VStack(spacing: 12) {
            // Month navigation header
            HStack {
                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left").padding(8)
                }
                Spacer()
                Text(displayMonth, format: .dateTime.month(.wide).year())
                    .font(.headline)
                Spacer()
                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right").padding(8)
                }
            }

            // Day-of-week headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
                // Leading empty cells
                ForEach(0..<leadingEmptyCount, id: \.self) { _ in
                    Color.clear.frame(height: 40)
                }
                // Day cells
                ForEach(daysInMonth, id: \.self) { day in
                    DayCell(day: day, patrols: patrols(on: day))
                }
            }

            // Legend
            if !patrolsInMonth.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Patrols this month")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    ForEach(patrolsInMonth, id: \.id) { patrol in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(patrol.endTime != nil ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text(patrol.areaName ?? "Unknown")
                                .font(.caption)
                            Spacer()
                            if let date = patrol.patrolDate {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: helpers

    private func shiftMonth(_ delta: Int) {
        displayMonth = Calendar.current.date(byAdding: .month, value: delta, to: displayMonth) ?? displayMonth
    }

    private var daysInMonth: [Date] {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: displayMonth)!
        return range.compactMap { day -> Date? in
            cal.date(bySetting: .day, value: day, of: displayMonth)
        }
    }

    private var leadingEmptyCount: Int {
        Calendar.current.component(.weekday, from: daysInMonth.first ?? displayMonth) - 1
    }

    private func patrols(on day: Date) -> [PatrolRecord] {
        patrols.filter { patrol in
            guard let d = patrol.patrolDate ?? patrol.startTime else { return false }
            return Calendar.current.isDate(d, inSameDayAs: day)
        }
    }

    private var patrolsInMonth: [PatrolRecord] {
        patrols.filter { patrol in
            guard let d = patrol.patrolDate ?? patrol.startTime else { return false }
            return Calendar.current.isDate(d, equalTo: displayMonth, toGranularity: .month)
        }
        .sorted { ($0.patrolDate ?? .distantPast) < ($1.patrolDate ?? .distantPast) }
    }
}

private struct DayCell: View {
    let day: Date
    let patrols: [PatrolRecord]

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    var body: some View {
        VStack(spacing: 2) {
            Text(Calendar.current.component(.day, from: day).description)
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isToday ? .white : .primary)
                .frame(width: 28, height: 28)
                .background(isToday ? Color.accentColor : Color.clear)
                .clipShape(Circle())

            if !patrols.isEmpty {
                HStack(spacing: 2) {
                    ForEach(patrols.prefix(3), id: \.id) { patrol in
                        Circle()
                            .fill(patrol.endTime != nil ? Color.green : Color.orange)
                            .frame(width: 5, height: 5)
                    }
                }
            } else {
                Color.clear.frame(height: 5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .background(patrols.isEmpty ? Color.clear : Color.green.opacity(0.07))
        .cornerRadius(6)
    }
}

// MARK: - List

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
