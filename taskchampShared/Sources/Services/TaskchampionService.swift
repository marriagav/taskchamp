import Foundation
import Taskchampion
import WidgetKit

// swiftlint:disable:next type_body_length
public class TaskchampionService {
    public static let shared = TaskchampionService()
    private var replica: Replica?
    private var path: String?
    public var needToSync = false
    private var currentTask: _Concurrency.Task<Void, Error>?

    /// Set by the app. Called when a sync starts and returns a closure to call when it ends.
    /// The app uses it to request background execution time, so iOS doesn't suspend the app in the
    /// middle of a sync while it holds the database lock. That gets the app killed (code 0xdead10cc).
    /// Extensions leave it nil because they can't request background time.
    @MainActor public var beginSyncActivity: (() -> () -> Void)?

    /// False while the app is in the background. Syncs requested then are deferred, not started.
    public private(set) var isSyncAllowed = true
    private var hasDeferredSync = false

    /// Stops new syncs from starting, e.g. when the app moves to the background.
    /// A sync that is already running keeps going.
    public func pauseSyncing() {
        isSyncAllowed = false
    }

    /// Allows syncs again. Returns true if a sync was requested while paused and should run now.
    public func resumeSyncing() -> Bool {
        isSyncAllowed = true
        let shouldSync = hasDeferredSync
        hasDeferredSync = false
        return shouldSync
    }

    public enum SyncType: Codable, CaseIterable {
        case remote
        case aws
        case gcp
        case local
        case none
    }

    public func getSyncServiceFromType(_ type: TaskchampionService.SyncType) -> SyncServiceProtocol.Type {
        switch type {
        case .none:
            return NoSyncService.self
        case .local:
            return ICloudSyncService.self
        case .remote:
            return RemoteSyncService.self
        case .gcp:
            return GcpSyncService.self
        case .aws:
            return AwsSyncService.self
        }
    }

    public func setDbUrl(path: String) throws {
        if replica != nil, self.path != nil, self.path == path {
            return
        }
        replica = Taskchampion.new_replica_on_disk(path, true, true)
        if replica == nil {
            throw TCError.genericError("Failed to create replica")
        }
        self.path = path
    }

    public func deleteReplica() throws {
        guard let path else {
            throw TCError.genericError("Database not set")
        }
        do {
            let newPath = path + "/taskchampion.sqlite3"
            try FileManager.default.removeItem(atPath: newPath)
            replica = nil
            self.path = nil
        } catch {
            throw TCError.genericError("Failed to delete replica: \(error.localizedDescription)")
        }
    }

    public func sync(syncType: SyncType, onSync: @escaping () -> Void = {}) async throws {
        try await performSync(syncType: syncType, onSync: onSync)
    }

    public func sync(onSync: @escaping () -> Void = {}) async throws {
        try await performSync(syncType: nil, onSync: onSync)
    }

    /// Runs a sync with `syncType`, or with the user's selected sync service when nil.
    private func performSync(syncType: SyncType?, onSync: @escaping () -> Void) async throws {
        // A sync started in the background can be suspended halfway while holding the database
        // lock, which gets the app killed. Remember it and run it once the app is active again.
        guard isSyncAllowed else {
            hasDeferredSync = true
            onSync()
            return
        }

        currentTask?.cancel()
        currentTask = .init {
            guard let replica else {
                throw TCError.genericError("Database not set")
            }

            let syncType: SyncType = syncType ?? FileService.shared.getSelectedSyncType() ?? .none
            let syncService = getSyncServiceFromType(syncType)

            // Keep the app running until this sync finishes, even if the user leaves the app.
            let endSyncActivity = await MainActor.run { self.beginSyncActivity?() }
            defer {
                if let endSyncActivity {
                    _Concurrency.Task { @MainActor in endSyncActivity() }
                }
            }

            do {
                let synced = try await syncService.sync(replica: replica)

                if synced {
                    needToSync = false
                } else {
                    needToSync = true
                }
                WidgetCenter.shared.reloadAllTimelines()
                onSync()
            } catch is CancellationError {
                // do nothing: task was canceled before finishing
            } catch {
                needToSync = true
                onSync()
            }
        }
        try await currentTask?.value
    }

    @MainActor
    public func getTasks(
        sortType: TasksHelper.TCSortType = .defaultSort,
        filter: TCFilter = TCFilter.defaultFilter
    ) throws -> [TCTask] {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
        var taskObjects: [TCTask] = []
        if filter.isDefaultFilter {
            taskObjects = try getPendingTasks()
            TCTask.markLatestTask(in: &taskObjects)
            TasksHelper.sortTasksWithSortType(&taskObjects, sortType: sortType)
            return taskObjects
        }

        let tasks = replica.all_tasks()
        guard let tasks else {
            throw TCError.genericError("Query was null")
        }
        taskObjects = tasks.compactMap {
            let task = TCTask.taskFactory(from: $0, withFilter: filter)
            if let task {
                return task
            }
            return nil
        }

        TCTask.markLatestTask(in: &taskObjects)
        TasksHelper.sortTasksWithSortType(&taskObjects, sortType: sortType)
        return taskObjects
    }

    @MainActor
    public func getAllProjects(onlyActive: Bool = false) -> [String] {
        guard let replica else { return [] }
        let rawTasks = onlyActive ? replica.pending_tasks() : replica.all_tasks()
        guard let rawTasks else { return [] }
        var seen = Set<String>()
        var projects: [String] = []
        for raw in rawTasks {
            let project = TCTask(from: raw).project ?? ""
            let trimmed = project.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !seen.contains(trimmed) else { continue }
            seen.insert(trimmed)
            projects.append(trimmed)
        }
        return projects.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    @MainActor
    public func getPendingTasks() throws -> [TCTask] {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }

        let tasks = replica.pending_tasks()
        guard let tasks else {
            throw TCError.genericError("Query was null")
        }
        return tasks.map { TCTask(from: $0) }
    }

    @MainActor
    public func getTask(uuid: String) throws -> TCTask {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
        let task = replica.get_task(uuid)
        guard let task else {
            throw TCError.genericError("Task not found")
        }
        return TCTask(from: task)
    }

    @MainActor
    public func togglePendingTasksStatus(uuids: Set<String>, onSync: @escaping () -> Void = {}) throws {
        for uuid in uuids {
            let task = try getTask(uuid: uuid)
            var newStatus: TCTask.Status = .pending
            if task.status == .pending {
                newStatus = .completed
            } else if task.status == .completed {
                newStatus = .pending
            }
            var updatedTask = task
            updatedTask.status = newStatus
            try updateTask(updatedTask, skipSync: true)
        }
        _Concurrency.Task.detached {
            try? await self.sync {
                onSync()
            }
        }
    }

    @MainActor
    public func updatePendingTasks(
        _ uuids: Set<String>,
        withStatus newStatus: TCTask.Status,
        onSync: @escaping () -> Void = {}
    ) throws {
        for uuid in uuids {
            let task = try getTask(uuid: uuid)
            var updatedTask = task
            updatedTask.status = newStatus
            try updateTask(updatedTask, skipSync: true)
        }
        _Concurrency.Task.detached {
            try? await self.sync {
                onSync()
            }
        }
    }

    public func updateTask(_ task: TCTask, skipSync: Bool = false, onSync: @escaping () -> Void = {}) throws {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
        let priority = (task.priority == TCTask.Priority.none || task.priority == nil) ? ""
            .intoRustString() : task
            .priority?.rawValue
            .intoRustString()
        let due = task.due?.timeIntervalSince1970.rounded()
        let dueString = due != nil ? String(Int(due ?? 0)) : nil

        var annotations: RustVec<Annotation>?
        if let annotation = task.rustAnnotationFromObsidianNote {
            annotations = RustVec<Annotation>()
            annotations?.push(value: annotation)
        }

        let task = replica.update_task(
            task.uuid.intoRustString(),
            task.description.intoRustString(),
            dueString?.intoRustString(),
            priority,
            task.project?.intoRustString(),
            task.status.rawValue.intoRustString(),
            annotations,
            task.rustVecOfTags
        )
        if task == nil {
            throw TCError.genericError("Failed to update task")
        }

        _ = replica.sync_no_server() // rebuild the working set

        if skipSync {
            return
        }

        _Concurrency.Task.detached {
            try? await self.sync {
                onSync()
            }
        }
    }

    public func startTask(_ uuid: String, onSync: @escaping () -> Void = {}) throws {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
        let task = replica.start_task(uuid.intoRustString())
        if task == nil {
            throw TCError.genericError("Failed to start task")
        }
        _ = replica.sync_no_server()
        _Concurrency.Task.detached {
            try? await self.sync {
                onSync()
            }
        }
    }

    public func stopTask(_ uuid: String, onSync: @escaping () -> Void = {}) throws {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
        let task = replica.stop_task(uuid.intoRustString())
        if task == nil {
            throw TCError.genericError("Failed to stop task")
        }
        _ = replica.sync_no_server()
        _Concurrency.Task.detached {
            try? await self.sync {
                onSync()
            }
        }
    }

    public func createTask(_ task: TCTask, onSync: @escaping () -> Void = {}) throws {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
        let priority = (task.priority == TCTask.Priority.none || task.priority == nil) ? "".intoRustString() : task
            .priority?.rawValue
            .intoRustString()
        let due = task.due?.timeIntervalSince1970.rounded()
        let dueString = due != nil ? String(Int(due ?? 0)) : nil

        let task = replica.create_task(
            task.uuid.intoRustString(),
            task.description.intoRustString(),
            dueString?.intoRustString(),
            priority,
            task.project?.intoRustString(),
            task.rustVecOfTags
        )
        if task == nil {
            throw TCError.genericError("Failed to create task")
        }

        _ = replica.sync_no_server() // rebuild the working set

        _Concurrency.Task.detached {
            try? await self.sync {
                onSync()
            }
        }
    }
}
