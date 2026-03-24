import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: TaskListViewModel
    @State private var showAddTask = false
    @State private var editingTask: RangerTask?

    init() {
        _viewModel = StateObject(wrappedValue: TaskListViewModel(
            persistence: AppEnvironment.shared.persistence,
            rangerID: AppEnvironment.shared.authManager.currentRangerID ?? UUID()
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.displayed.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddTask = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Toggle("Show Completed", isOn: $viewModel.showCompleted)
                        Divider()
                        Button("All Priorities") { viewModel.filterPriority = nil }
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Button {
                                viewModel.filterPriority = viewModel.filterPriority == p ? nil : p
                            } label: {
                                Label(p.displayName, systemImage: viewModel.filterPriority == p ? "checkmark" : p.icon)
                            }
                        }
                    } label: {
                        Image(systemName: viewModel.filterPriority != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddTask, onDismiss: { viewModel.load() }) {
                AddTaskView()
            }
            .sheet(item: $editingTask, onDismiss: { viewModel.load() }) { task in
                EditTaskView(task: task)
            }
            .onAppear { viewModel.load() }
        }
    }

    private var taskList: some View {
        List {
            if viewModel.overdueCount > 0 && !viewModel.showCompleted {
                Section {
                    Label("\(viewModel.overdueCount) overdue task\(viewModel.overdueCount == 1 ? "" : "s")", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.subheadline.bold())
                }
            }

            ForEach(viewModel.displayed) { task in
                TaskRow(task: task, onToggle: { viewModel.toggle(task) })
                    .contentShape(Rectangle())
                    .onTapGesture { editingTask = task }
            }
            .onDelete { offsets in
                offsets.map { viewModel.displayed[$0] }.forEach { viewModel.delete($0) }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(viewModel.showCompleted ? "No tasks" : "All clear")
                .font(.title3.bold())
            Text(viewModel.showCompleted ? "Create a task with the + button." : "No pending tasks. Tap + to add one.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct TaskRow: View {
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
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isComplete ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title ?? "Untitled")
                    .font(.subheadline.bold())
                    .strikethrough(task.isComplete)
                    .foregroundColor(task.isComplete ? .secondary : .primary)

                HStack(spacing: 8) {
                    Label(priority.displayName, systemImage: priority.icon)
                        .font(.caption)
                        .foregroundColor(priority.color)

                    if let due = task.dueDate {
                        Label(dueDateLabel(due), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(isOverdue ? .red : .secondary)
                    }

                    if task.sourceTreatment != nil {
                        Label("Auto", systemImage: "wand.and.stars")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(task.isComplete ? 0.6 : 1)
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
