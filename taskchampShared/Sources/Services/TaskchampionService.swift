import Foundation
import Taskchampion

public class TaskchampionService {
    public static let shared = TaskchampionService()
    private var replica: Replica?

    public func setDbUrl(path: String) {
        // TODO: use replica from disk
        // replica = Taskchampion.new_replica_in_memory()
        replica = Taskchampion.new_replica_on_disk(path, false, true)
    }

    public func getTasks(
        sortType: TasksHelper.TCSortType = .defaultSort,
        filter _: TCFilter = TCFilter.defaultFilter
    ) throws -> [TCTask] {
        var taskObjects: [TCTask] = []
        let tasks = replica?.pending_tasks()
        guard let tasks else {
            throw TCError.genericError("Query was null")
        }
        for task in tasks {
            print("\nTASK Desc", task.get_description().toString())
            print("TASK UUID", task.get_uuid().to_string().toString())
            print("TASK STATUS", task.get_status().get_value().toString())
            print("TASK PRIO", task.get_priority().toString())
            print("TASK DUE", task.get_due()?.toString() ?? "0")
            print("TASK PROJECT", task.get_project()?.toString() ?? "No project")
            for annotation in task.get_annotations() {
                print("TASK ANNOTATION", annotation.get_description().toString())
            }

            // print("TASK DESCRIPTION", task
            // print("TASK UUID", task.
            // print("TASK PROJECT", task.get_project())
            // TODO: TCTask init from taskchampion task
            // taskObjects.append(task)
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
