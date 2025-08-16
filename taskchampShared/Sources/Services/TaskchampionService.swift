import Foundation
import Taskchampion

public class TaskchampionService {
    public static let shared = TaskchampionService()
    private var replica: Replica?

    public func setDbUrl(path: String) {
        replica = Taskchampion.new_replica_on_disk(path, false, true)
    }

    public func getTasks(
        sortType: TasksHelper.TCSortType = .defaultSort,
        filter _: TCFilter = TCFilter.defaultFilter
    ) throws -> [TCTask] {
        let tasks = replica?.pending_tasks()
        guard let tasks else {
            throw TCError.genericError("Query was null")
        }
        var taskObjects: [TCTask] = tasks.map {
            return TCTask(from: $0)
        }
        // TODO: use filters
        TasksHelper.sortTasksWithSortType(&taskObjects, sortType: sortType)
        return taskObjects
    }

    public func getTask(uuid _: String) throws -> TCTask {
        // TODO:
        throw TCError.genericError("Not implemented")
    }

    public func togglePendingTasksStatus(uuids _: Set<String>) throws {
        // TODO:
        throw TCError.genericError("Not implemented")
    }

    public func updatePendingTasks(_: Set<String>, withStatus _: TCTask.Status) throws {
        // TODO:
        throw TCError.genericError("Not implemented")
    }

    public func updateTask(_: TCTask) throws {
        // TODO:
        throw TCError.genericError("Not implemented")
    }

    public func createTask(task _: TCTask) throws {
        // TODO:
        let uuid = Taskchampion.uuid_v4()
        var ops = Taskchampion.new_operations()
        ops = Taskchampion.create_task(uuid, ops)
        // throw TCError.genericError("Not implemented")
    }
}
