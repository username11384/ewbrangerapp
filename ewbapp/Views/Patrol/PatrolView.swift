import SwiftUI
import Combine

struct PatrolView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: PatrolViewModel
    @State private var elapsedSeconds: Int = 0
    @State private var fieldNotes: String = ""

    init() {
        _viewModel = StateObject(wrappedValue: PatrolViewModel(
            persistence: AppEnvironment.shared.persistence,
            rangerID: AppEnvironment.shared.authManager.currentRangerID ?? UUID()
        ))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.paper.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 54)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    calendarCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    if viewModel.activePatrol != nil {
                        activeCard
                            .padding(.horizontal, 16)
                            .padding(.bottom, 32)
                    } else {
                        idleCard
                            .padding(.horizontal, 16)
                            .padding(.bottom, 32)
                    }
                }
            }
        }
        .onAppear { viewModel.load() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if viewModel.activePatrol != nil {
                elapsedSeconds += 1
            }
        }
        .onChange(of: viewModel.activePatrol == nil) { _, isNil in
            if isNil { elapsedSeconds = 0; fieldNotes = "" }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Patrol")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.ink)
            if viewModel.activePatrol != nil {
                Text("Patrol in progress")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.ink3)
            } else {
                Text("No active patrol")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.ink3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var calendarCard: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("This week")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.ink)
                Spacer()
                Text("\(weekPatrolCount) patrol\(weekPatrolCount == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color.ink3)
            }

            HStack(spacing: 0) {
                ForEach(currentWeekDays(), id: \.self) { day in
                    weekDayCell(day)
                }
            }
        }
        .dsCard(padding: 12)
    }

    private func weekDayCell(_ date: Date) -> some View {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(date)
        let dayLetter = date.formatted(.dateTime.weekday(.narrow))
        let dayNumber = cal.component(.day, from: date)
        let hasPatrol = viewModel.patrols.contains { patrol in
            guard let d = patrol.patrolDate ?? patrol.startTime else { return false }
            return cal.isDate(d, inSameDayAs: date)
        }

        return VStack(spacing: 4) {
            Text(dayLetter)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(Color.ink3)

            ZStack {
                if isToday {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.euc)
                        .frame(width: 32, height: 32)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.clear)
                        .frame(width: 32, height: 32)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
                }
                Text("\(dayNumber)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isToday ? .white : Color.ink)
            }

            Circle()
                .fill(hasPatrol ? Color.ochre : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity)
    }

    private var weekPatrolCount: Int {
        let days = currentWeekDays()
        guard let first = days.first, let last = days.last else { return 0 }
        let cal = Calendar.current
        return viewModel.patrols.filter { patrol in
            guard let d = patrol.patrolDate ?? patrol.startTime else { return false }
            return d >= cal.startOfDay(for: first) && d <= cal.date(byAdding: .day, value: 1, to: last)!
        }.count
    }

    private func currentWeekDays() -> [Date] {
        let cal = Calendar.current
        let today = Date()
        var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        comps.weekday = 2
        guard let monday = cal.date(from: comps) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    private let checklistItems = [
        "Water — 4L per person",
        "Fuel — quad and ute",
        "UHF radio + spare battery",
        "First aid kit",
        "Sunscreen + hat"
    ]

    @State private var preChecklistState: [Bool] = Array(repeating: false, count: 5)

    private var allPreChecked: Bool { preChecklistState.allSatisfy { $0 } }

    private var idleCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pre-departure checklist")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.ink)
                Text("Complete before starting patrol")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.ink3)
            }
            .padding(.bottom, 14)

            VStack(spacing: 0) {
                ForEach(checklistItems.indices, id: \.self) { i in
                    VStack(spacing: 0) {
                        if i > 0 {
                            Divider().background(Color.lineBase.opacity(0.12))
                        }
                        Button {
                            preChecklistState[i].toggle()
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    if preChecklistState[i] {
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(Color.euc)
                                            .frame(width: 24, height: 24)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(Color.clear)
                                            .frame(width: 24, height: 24)
                                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.lineBase.opacity(0.22), lineWidth: 1.5))
                                    }
                                }
                                Text(checklistItems[i])
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color.ink)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.bottom, 18)

            VStack(alignment: .leading, spacing: 8) {
                Text("PATROL AREA")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.ink3)
                    .kerning(0.4)

                Picker("Patrol Area", selection: $viewModel.selectedAreaName) {
                    ForEach(PortStewartZones.patrolAreas, id: \.self) { area in
                        Text(area).tag(area)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.paperDeep)
                .cornerRadius(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 18)

            Button {
                Task { await viewModel.startPatrol() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Start patrol")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(allPreChecked ? .white : Color.ink3)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .background(allPreChecked ? Color.euc : Color.paperDeep)
                .cornerRadius(12)
            }
            .disabled(!allPreChecked)
        }
        .dsCard(padding: 16)
    }

    private var activeCard: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ON PATROL · \((viewModel.activePatrol?.areaName ?? "").uppercased())")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .kerning(0.3)

                Text(timerString)
                    .font(.system(size: 42, weight: .semibold).monospacedDigit())
                    .foregroundColor(.white)
                    .tracking(-0.5)

                Text("3 sightings logged")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 18)
            .padding(.horizontal, 16)
            .background(Color.euc)

            VStack(alignment: .leading, spacing: 10) {
                Text("FIELD NOTES")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.ink3)
                    .kerning(0.4)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $fieldNotes)
                        .font(.system(size: 14))
                        .foregroundColor(Color.ink)
                        .scrollContentBackground(.hidden)
                        .background(Color.paperDeep)
                        .cornerRadius(12)
                        .frame(minHeight: 72)

                    if fieldNotes.isEmpty {
                        Text("What's on country today?")
                            .font(.system(size: 14))
                            .foregroundColor(Color.ink3)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }

                Button {
                    Task { await viewModel.finishPatrol() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("End patrol")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .background(Color.statusActive)
                    .cornerRadius(12)
                }
                .padding(.top, 4)
            }
            .padding(14)
        }
        .background(Color.card)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
        .clipped()
    }

    private var timerString: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
