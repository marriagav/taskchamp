import Foundation
import Taskchampion
import WidgetKit

public class TaskchampionService {
    public static let shared = TaskchampionService()
    private var replica: Replica?
    private var path: String?
    public var needToSync = false

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

    public func sync(syncType: SyncType) async throws {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }

        let syncService = getSyncServiceFromType(syncType)

        do {
            let synced = try await syncService.sync(replica: replica)

            if synced {
                needToSync = false
            } else {
                needToSync = true
            }
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            needToSync = true
        }
    }

    public func sync() async throws {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }

        let syncType: SyncType = FileService.shared.getSelectedSyncType() ?? .none
        let syncService = getSyncServiceFromType(syncType)

        do {
            let synced = try await syncService.sync(replica: replica)

            if synced {
                needToSync = false
            } else {
                needToSync = true
            }
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            needToSync = true
        }
    }

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

        TasksHelper.sortTasksWithSortType(&taskObjects, sortType: sortType)
        return taskObjects
    }

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

    public func togglePendingTasksStatus(uuids: Set<String>) throws {
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
            try updateTask(updatedTask)
        }
    }

    public func updatePendingTasks(_ uuids: Set<String>, withStatus newStatus: TCTask.Status) throws {
        for uuid in uuids {
            let task = try getTask(uuid: uuid)
            var updatedTask = task
            updatedTask.status = newStatus
            try updateTask(updatedTask)
        }
    }

    public func updateTask(_ task: TCTask) throws {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
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
            task.priority?.rawValue.intoRustString(),
            task.project?.intoRustString(),
            task.status.rawValue.intoRustString(),
            annotations
        )
        if task == nil {
            throw TCError.genericError("Failed to update task")
        }

        replica.sync_no_server() // rebuild the working set

        _Concurrency.Task {
            try? await sync()
        }
    }

    public func createTask(_ task: TCTask) throws {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
        let due = task.due?.timeIntervalSince1970.rounded()
        let dueString = due != nil ? String(Int(due ?? 0)) : nil
        let task = replica.create_task(
            task.uuid.intoRustString(),
            task.description.intoRustString(),
            dueString?.intoRustString(),
            task.priority?.rawValue.intoRustString(),
            task.project?.intoRustString()
        )
        if task == nil {
            throw TCError.genericError("Failed to create task")
        }

        replica.sync_no_server() // rebuild the working set

        _Concurrency.Task {
            try? await sync()
        }
    }
}
