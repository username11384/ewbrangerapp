import XCTest
import CoreData
@testable import ewbapp

@MainActor
final class TaskRepositoryTests: XCTestCase {

    var persistence: PersistenceController!
    var repository: TaskRepository!
    private var rangerID: UUID!
    private var otherRangerID: UUID!
    private var createdTaskIDs: [UUID] = []

    override func setUp() async throws {
        try await super.setUp()
        persistence = PersistenceController.preview
        repository = TaskRepository(persistence: persistence)
        rangerID = UUID()
        otherRangerID = UUID()
        createdTaskIDs = []
        try ensureRanger(id: rangerID, name: "Primary")
        try ensureRanger(id: otherRangerID, name: "Other")
    }

    override func tearDown() async throws {
        try deleteCreatedTasks()
        persistence = nil
        repository = nil
        rangerID = nil
        otherRangerID = nil
        createdTaskIDs = []
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func ensureRanger(id: UUID, name: String) throws {
        let ctx = persistence.mainContext
        let pred = NSPredicate(format: "id == %@", id as CVarArg)
        if try ctx.fetchFirst(RangerProfile.self, predicate: pred) == nil {
            let r = RangerProfile(context: ctx)
            r.id = id
            r.displayName = name
            r.role = RangerRole.ranger.rawValue
            r.createdAt = Date()
            r.updatedAt = Date()
            r.isCurrentDevice = false
            r.syncStatus = SyncStatus.synced.rawValue
            try ctx.save()
        }
    }

    @discardableResult
    private func createTaskTracked(
        title: String = "Task \(UUID().uuidString.prefix(6))",
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        ranger: UUID? = nil
    ) async throws -> RangerTask {
        let owner = ranger ?? rangerID!
        let task = try await repository.createTask(
            title: title,
            notes: nil,
            priority: priority,
            dueDate: dueDate,
            rangerID: owner
        )
        // Wait for background-context merge into main context.
        try await Task.sleep(nanoseconds: 200_000_000)
        if let id = task.id { createdTaskIDs.append(id) }
        return task
    }

    private func deleteCreatedTasks() throws {
        let ctx = persistence.mainContext
        for id in createdTaskIDs {
            if let t = try ctx.fetchFirst(RangerTask.self, predicate: NSPredicate(format: "id == %@", id as CVarArg)) {
                ctx.delete(t)
            }
        }
        if ctx.hasChanges { try ctx.save() }
    }

    private func fetchMine() throws -> [RangerTask] {
        try repository.fetchAllTasks(rangerID: rangerID)
    }

    // MARK: - Empty store

    func test_fetchAllTasks_forRangerWithNoTasks_returnsEmpty() throws {
        let brandNewRanger = UUID()
        try ensureRanger(id: brandNewRanger, name: "No Tasks")
        let tasks = try repository.fetchAllTasks(rangerID: brandNewRanger)
        XCTAssertTrue(tasks.isEmpty)
    }

    // MARK: - Create + fetch round-trip

    func test_createTask_isFetchableByRangerID() async throws {
        let task = try await createTaskTracked(title: "Unique round-trip \(UUID().uuidString)", priority: .high)

        let fetched = try fetchMine()
        XCTAssertTrue(fetched.contains { $0.id == task.id })
    }

    func test_createTask_persistsTitleAndPriority() async throws {
        let uniqueTitle = "Title-\(UUID().uuidString)"
        _ = try await createTaskTracked(title: uniqueTitle, priority: .high)

        let fetched = try fetchMine()
        let match = fetched.first { $0.title == uniqueTitle }
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.priority, TaskPriority.high.rawValue)
    }

    // MARK: - Toggle complete persists

    func test_toggleComplete_persistsAcrossFetch() async throws {
        let task = try await createTaskTracked()
        XCTAssertFalse(task.isComplete)

        try await repository.toggleComplete(task)
        try await Task.sleep(nanoseconds: 200_000_000)

        let fetched = try fetchMine()
        let match = fetched.first { $0.id == task.id }
        XCTAssertNotNil(match)
        XCTAssertTrue(match?.isComplete == true)
        XCTAssertNotNil(match?.completedAt)
    }

    func test_toggleComplete_twice_returnsToIncomplete_andClearsCompletedAt() async throws {
        let task = try await createTaskTracked()
        try await repository.toggleComplete(task)
        try await Task.sleep(nanoseconds: 200_000_000)
        try await repository.toggleComplete(task)
        try await Task.sleep(nanoseconds: 200_000_000)

        let fetched = try fetchMine()
        let match = fetched.first { $0.id == task.id }
        XCTAssertNotNil(match)
        XCTAssertFalse(match?.isComplete == true)
        XCTAssertNil(match?.completedAt)
    }

    // MARK: - Delete

    func test_deleteTask_removesFromSubsequentFetch() async throws {
        let task = try await createTaskTracked()
        let beforeIDs = try fetchMine().compactMap { $0.id }
        XCTAssertTrue(beforeIDs.contains(task.id!))

        try await repository.deleteTask(task)
        try await Task.sleep(nanoseconds: 200_000_000)

        let afterIDs = try fetchMine().compactMap { $0.id }
        XCTAssertFalse(afterIDs.contains(task.id!))
        createdTaskIDs.removeAll { $0 == task.id }
    }

    // MARK: - Ordering

    func test_fetchAllTasks_incompleteTasksSortedBeforeCompleteTasks() async throws {
        let a = try await createTaskTracked(title: "A-\(UUID().uuidString)")
        let b = try await createTaskTracked(title: "B-\(UUID().uuidString)")
        try await repository.toggleComplete(a)
        try await Task.sleep(nanoseconds: 200_000_000)

        let fetched = try fetchMine()
        let aIdx = fetched.firstIndex { $0.id == a.id }
        let bIdx = fetched.firstIndex { $0.id == b.id }
        XCTAssertNotNil(aIdx)
        XCTAssertNotNil(bIdx)
        XCTAssertLessThan(bIdx!, aIdx!)
    }

    func test_fetchAllTasks_earlierDueDateSortsBefore_amongIncomplete() async throws {
        let now = Date()
        let later = try await createTaskTracked(title: "later-\(UUID().uuidString)", dueDate: now.addingTimeInterval(86_400))
        let sooner = try await createTaskTracked(title: "sooner-\(UUID().uuidString)", dueDate: now.addingTimeInterval(3600))

        let fetched = try fetchMine()
        let laterIdx = fetched.firstIndex { $0.id == later.id }
        let soonerIdx = fetched.firstIndex { $0.id == sooner.id }
        XCTAssertNotNil(laterIdx)
        XCTAssertNotNil(soonerIdx)
        XCTAssertLessThan(soonerIdx!, laterIdx!)
    }

    // MARK: - Past due dates are still fetchable

    func test_fetchAllTasks_includesTaskWithPastDueDate() async throws {
        let past = Date().addingTimeInterval(-86_400 * 7)
        let task = try await createTaskTracked(title: "overdue-\(UUID().uuidString)", dueDate: past)

        let fetched = try fetchMine()
        XCTAssertTrue(fetched.contains { $0.id == task.id })
    }

    // MARK: - Per-ranger filtering

    func test_fetchAllTasks_byRangerID_excludesOtherRangersTasks() async throws {
        let mine = try await createTaskTracked(title: "mine-\(UUID().uuidString)", ranger: rangerID)
        let theirs = try await createTaskTracked(title: "theirs-\(UUID().uuidString)", ranger: otherRangerID)

        let myTasks = try repository.fetchAllTasks(rangerID: rangerID)
        XCTAssertTrue(myTasks.contains { $0.id == mine.id })
        XCTAssertFalse(myTasks.contains { $0.id == theirs.id })

        let theirTasks = try repository.fetchAllTasks(rangerID: otherRangerID)
        XCTAssertTrue(theirTasks.contains { $0.id == theirs.id })
        XCTAssertFalse(theirTasks.contains { $0.id == mine.id })
    }

    func test_fetchAllTasks_withNilRangerID_returnsAllTasks() async throws {
        let mine = try await createTaskTracked(ranger: rangerID)
        let theirs = try await createTaskTracked(ranger: otherRangerID)

        let all = try repository.fetchAllTasks(rangerID: nil)
        XCTAssertTrue(all.contains { $0.id == mine.id })
        XCTAssertTrue(all.contains { $0.id == theirs.id })
    }

    // MARK: - Initial state on create

    func test_createTask_initiallyNotComplete_andHasPendingCreateSyncStatus() async throws {
        let task = try await createTaskTracked()
        let fetched = try fetchMine().first { $0.id == task.id }
        XCTAssertNotNil(fetched)
        XCTAssertFalse(fetched?.isComplete == true)
        XCTAssertEqual(fetched?.syncStatus, SyncStatus.pendingCreate.rawValue)
    }
}
