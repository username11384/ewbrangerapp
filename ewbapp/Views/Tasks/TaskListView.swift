import SwiftUI

enum TaskFilter: String, CaseIterable {
    case all, mine, done
}

struct TaskListView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: TaskListViewModel
    @State private var showAddTask = false
    @State private var editingTask: RangerTask?
    @State private var filter: TaskFilter = .all

    private var currentRangerID: UUID {
        AppEnvironment.shared.authManager.currentRangerID ?? UUID()
    }

    init() {
        _viewModel = StateObject(wrappedValue: TaskListViewModel(
            persistence: AppEnvironment.shared.persistence,
            rangerID: AppEnvironment.shared.authManager.currentRangerID ?? UUID()
        ))
    }

    private var filteredTasks: [RangerTask] {
        switch filter {
        case .all:
            return viewModel.displayed.filter { !$0.isComplete }
        case .mine:
            return viewModel.displayed.filter { !$0.isComplete && $0.assignedRanger?.id == currentRangerID }
        case .done:
            return viewModel.tasks.filter { $0.isComplete }
        }
    }

    private var allCount: Int { viewModel.tasks.filter { !$0.isComplete }.count }

    var body: some View {
        ZStack(alignment: .top) {
            Color.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                filterChips
                taskScroll
            }
        }
        .sheet(isPresented: $showAddTask, onDismiss: { viewModel.load() }) {
            AddTaskView()
        }
        .sheet(item: $editingTask, onDismiss: { viewModel.load() }) { task in
            EditTaskView(task: task)
        }
        .onAppear {
            viewModel.showCompleted = true
            viewModel.load()
        }
    }

    private var topBar: some View {
        ZStack {
            Text("Tasks")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.ink)
                .frame(maxWidth: .infinity)
            HStack {
                Spacer()
                Button {
                    showAddTask = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.euc)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                filterChip(label: "All · \(allCount)", value: .all)
                filterChip(label: "Mine", value: .mine)
                filterChip(label: "Done", value: .done)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private func filterChip(label: String, value: TaskFilter) -> some View {
        let active = filter == value
        return Button {
            filter = value
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(active ? .white : Color.ink3)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(active ? Color.euc : Color.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
        }
    }

    private var taskScroll: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredTasks) { task in
                    TaskCard(task: task, onToggle: { viewModel.toggle(task) })
                        .contentShape(Rectangle())
                        .onTapGesture { editingTask = task }
                        .swipeActions(edge: .trailing) {
                            Button {
                                viewModel.toggle(task)
                            } label: {
                                Label("Done", systemImage: "checkmark")
                            }
                            .tint(Color.statusCleared)
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }
}

private struct TaskCard: View {
    let task: RangerTask
    let onToggle: () -> Void

    private var priority: TaskPriority {
        TaskPriority(rawValue: task.priority ?? "medium") ?? .medium
    }

    private var isOverdue: Bool {
        guard !task.isComplete, let due = task.dueDate else { return false }
        return due < Date()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            checkboxButton
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title ?? "Untitled")
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundColor(task.isComplete ? Color.ink3 : Color.ink)
                    .strikethrough(task.isComplete, color: Color.ink3)
                    .fixedSize(horizontal: false, vertical: true)
                metaRow
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(task.isComplete ? Color.paperDeep : Color.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
    }

    private var checkboxButton: some View {
        Button(action: onToggle) {
            ZStack {
                if task.isComplete {
                    Circle()
                        .fill(Color.statusCleared)
                        .frame(width: 26, height: 26)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(Color.lineBase.opacity(0.22), lineWidth: 1.5))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var metaRow: some View {
        HStack(spacing: 6) {
            priorityChip
            if let due = task.dueDate {
                dueDateChip(due)
            }
            if let ranger = task.assignedRanger, let name = ranger.displayName {
                rangerChip(name)
            }
        }
    }

    private var priorityChip: some View {
        let (bg, fg): (Color, Color) = {
            switch priority {
            case .high:   return (Color.statusActiveSoft, Color.statusActive)
            case .medium: return (Color.statusTreatSoft, Color.statusTreat)
            case .low:    return (Color.eucSoft, Color.euc)
            }
        }()
        return Text(priority.displayName.uppercased())
            .font(.system(size: 10.5, weight: .bold))
            .foregroundColor(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .clipShape(Capsule())
    }

    private func dueDateChip(_ date: Date) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "calendar")
                .font(.system(size: 9.5, weight: .semibold))
            Text(dueDateLabel(date))
                .font(.system(size: 10.5, weight: .semibold))
        }
        .foregroundColor(isOverdue ? Color.statusActive : Color.ink3)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(isOverdue ? Color.statusActiveSoft : Color.paperDeep)
        .clipShape(Capsule())
    }

    private func rangerChip(_ name: String) -> some View {
        let initials = name.split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0) }.joined()
        return Text(initials.isEmpty ? name.prefix(2).uppercased() : initials.uppercased())
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundColor(Color.ink3)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.paperDeep)
            .clipShape(Capsule())
    }

    private func dueDateLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        if isOverdue {
            let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
            return "\(days)d overdue"
        }
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: date)
    }
}
