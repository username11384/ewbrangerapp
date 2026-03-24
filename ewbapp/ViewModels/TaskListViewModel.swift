import Combine
import Foundation

@MainActor
final class TaskListViewModel: ObservableObject {
    @Published var tasks: [RangerTask] = []
    @Published var showCompleted = false
    @Published var filterPriority: TaskPriority? = nil

    private let repository: TaskRepository
    private let rangerID: UUID

    init(persistence: PersistenceController, rangerID: UUID) {
        self.repository = TaskRepository(persistence: persistence)
        self.rangerID = rangerID
        load()
    }

    func load() {
        tasks = (try? repository.fetchAllTasks(rangerID: rangerID)) ?? []
    }

    var displayed: [RangerTask] {
        tasks.filter { task in
            if !showCompleted && task.isComplete { return false }
            if let p = filterPriority, task.priority != p.rawValue { return false }
            return true
        }
        .sorted {
            let p0 = TaskPriority(rawValue: $0.priority ?? "medium")?.sortOrder ?? 1
            let p1 = TaskPriority(rawValue: $1.priority ?? "medium")?.sortOrder ?? 1
            if $0.isComplete != $1.isComplete { return !$0.isComplete }
            if p0 != p1 { return p0 < p1 }
            if let d0 = $0.dueDate, let d1 = $1.dueDate { return d0 < d1 }
            if $0.dueDate != nil { return true }
            if $1.dueDate != nil { return false }
            return ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
        }
    }

    var overdueCount: Int {
        tasks.filter { !$0.isComplete && ($0.dueDate ?? .distantFuture) < Date() }.count
    }

    func toggle(_ task: RangerTask) {
        Task {
            try? await repository.toggleComplete(task)
            load()
        }
    }

    func delete(_ task: RangerTask) {
        Task {
            try? await repository.deleteTask(task)
            load()
        }
    }
}
