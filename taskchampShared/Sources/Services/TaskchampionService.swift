import Foundation
import Taskchampion

public class TaskchampionService {
    public static let shared = TaskchampionService()
    private var replica: Replica?

    public func setDbUrl(_ path: String) {
        var newPath = path
        if path.hasSuffix("taskchampion.sqlite3") {
            newPath = String(path.dropLast("taskchampion.sqlite3".count))
        }
        replica = Taskchampion.new_replica_on_disk(newPath, false, true)
    }

    public func getTasks(
        sortType: TasksHelper.TCSortType = .defaultSort,
        filter _: TCFilter = TCFilter.defaultFilter
    ) throws -> [TCTask] {
        var taskObjects: [TCTask] = []
        let tasks = replica?.all_task_data()
        print("DEBUG: Tasks: \(tasks)")
        guard let tasks else {
            throw TCError.genericError("Query was null")
        }
        for task in tasks {
            let properties = task.properties()
            for property in properties {
                print("DEBUG: Property: \(property.as_str().toString())")
            }
            print("DEBUG: Task UUID", task.get_uuid())
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
        throw TCError.genericError("Not implemented")
    }
}
