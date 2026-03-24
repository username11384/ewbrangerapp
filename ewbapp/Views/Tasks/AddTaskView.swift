import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnv: AppEnvironment

    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TaskPriority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Label(p.displayName, systemImage: p.icon)
                                .foregroundColor(p.color)
                                .tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        guard let rangerID = appEnv.authManager.currentRangerID else { return }
        isSaving = true
        let repo = TaskRepository(persistence: appEnv.persistence)
        Task {
            try? await repo.createTask(
                title: title.trimmingCharacters(in: .whitespaces),
                notes: notes.isEmpty ? nil : notes,
                priority: priority,
                dueDate: hasDueDate ? dueDate : nil,
                rangerID: rangerID
            )
            await MainActor.run { dismiss() }
        }
    }
}

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnv: AppEnvironment

    let task: RangerTask

    @State private var title: String
    @State private var notes: String
    @State private var priority: TaskPriority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var isSaving = false

    init(task: RangerTask) {
        self.task = task
        _title = State(initialValue: task.title ?? "")
        _notes = State(initialValue: task.notes ?? "")
        _priority = State(initialValue: TaskPriority(rawValue: task.priority ?? "medium") ?? .medium)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Label(p.displayName, systemImage: p.icon)
                                .tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                    }
                }

                if let treatment = task.sourceTreatment {
                    Section("Source") {
                        Label("Auto-generated from \(TreatmentMethod(rawValue: treatment.method ?? "")?.displayName ?? "treatment")", systemImage: "wand.and.stars")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        let repo = TaskRepository(persistence: appEnv.persistence)
        Task {
            try? await repo.updateTask(
                task,
                title: title.trimmingCharacters(in: .whitespaces),
                notes: notes.isEmpty ? nil : notes,
                priority: priority,
                dueDate: hasDueDate ? dueDate : nil
            )
            await MainActor.run { dismiss() }
        }
    }
}
