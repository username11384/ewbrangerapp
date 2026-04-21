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
        VStack(spacing: DSSpace.md) {
            // Month navigation header
            HStack {
                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .padding(DSSpace.sm)
                        .foregroundStyle(Color.dsPrimary)
                }
                Spacer()
                Text(displayMonth, format: .dateTime.month(.wide).year())
                    .font(DSFont.headline)
                    .foregroundStyle(Color.dsInk)
                Spacer()
                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .padding(DSSpace.sm)
                        .foregroundStyle(Color.dsPrimary)
                }
            }

            // Day-of-week headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(DSFont.caption)
                        .foregroundStyle(Color.dsInk3)
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
                Divider().background(Color.dsDivider)
                VStack(alignment: .leading, spacing: DSSpace.sm) {
                    Text("Patrols this month")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.dsInk3)
                    ForEach(patrolsInMonth, id: \.id) { patrol in
                        HStack(spacing: DSSpace.sm) {
                            Circle()
                                .fill(patrol.endTime != nil ? Color.dsStatusCleared : Color.dsStatusTreat)
                                .frame(width: 8, height: 8)
                            Text(patrol.areaName ?? "Unknown")
                                .font(DSFont.caption)
                                .foregroundStyle(Color.dsInk)
                            Spacer()
                            if let date = patrol.patrolDate {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                                    .font(DSFont.caption)
                                    .foregroundStyle(Color.dsInk3)
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
                .font(DSFont.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? Color.white : Color.dsInk)
                .frame(width: 28, height: 28)
                .background(isToday ? Color.dsPrimary : Color.clear)
                .clipShape(Circle())

            if !patrols.isEmpty {
                HStack(spacing: 2) {
                    ForEach(patrols.prefix(3), id: \.id) { patrol in
                        Circle()
                            .fill(patrol.endTime != nil ? Color.dsStatusCleared : Color.dsStatusTreat)
                            .frame(width: 5, height: 5)
                    }
                }
            } else {
                Color.clear.frame(height: 5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .background(patrols.isEmpty ? Color.clear : Color.dsPrimary.opacity(0.07))
        .cornerRadius(DSRadius.xs)
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
        HStack(spacing: DSSpace.md) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle.dotted")
                .foregroundStyle(isComplete ? Color.dsStatusCleared : Color.dsStatusTreat)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(patrol.areaName ?? "Unknown Area")
                    .font(DSFont.headline)
                    .foregroundStyle(Color.dsInk)
                if let date = patrol.patrolDate {
                    Text(date, style: .date)
                        .font(DSFont.caption)
                        .foregroundStyle(Color.dsInk3)
                }
            }
            Spacer()
            Text(isComplete ? "Done" : "Active")
                .font(DSFont.badge)
                .foregroundStyle(isComplete ? Color.dsStatusCleared : Color.dsStatusTreat)
        }
        .padding(.vertical, 4)
    }
}
