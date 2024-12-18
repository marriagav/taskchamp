import Foundation
import SQLite
import WidgetKit

public class DBService {
    enum TasksColumns {
        static let uuid = SQLite.Expression<String>("uuid")
        static let data = SQLite.Expression<String>("data")
    }

    public static let shared = DBService()
    private var dbConnection: Connection?

    private init() {}

    public func setDbUrl(_ path: String) {
        do {
            dbConnection = try Connection(path)
        } catch {
            print(error)
        }
    }

    public func getPendingTasks(sortType: TasksHelper.TCSortType = .defaultSort) throws -> [TCTask] {
        var taskObjects: [TCTask] = []
        let tasks = Table("tasks")
        let query = tasks.select(TasksColumns.data, TasksColumns.uuid)
            .filter(TasksColumns.data.like("%\"status\":\"pending\"%"))
        WidgetCenter.shared.reloadAllTimelines()
        let queryTasks = try dbConnection?.prepare(query)
        guard let queryTasks else {
            throw TCError.genericError("Query was null")
        }
        for task in queryTasks {
            if let taskObject = try parseTask(row: task) {
                taskObjects.append(taskObject)
            }
        }
        TasksHelper.sortTasksWithSortType(&taskObjects, sortType: sortType)
        return taskObjects
    }

    public func getTask(uuid: String) throws -> TCTask {
        let tasks = Table("tasks")
        let query = tasks.filter(uuid == TasksColumns.uuid)
        let queryTasks = try dbConnection?.prepare(query)
        guard let queryTasks else {
            throw TCError.genericError("Query was null")
        }
        for task in queryTasks {
            let taskObject = try parseTask(row: task)
            if let taskObject {
                return taskObject
            }
        }
        throw TCError.genericError("Task not found")
    }

    private func parseTask(row: Row) throws -> TCTask? {
        let jsonObject = row[TasksColumns.data]
        let jsonData = jsonObject.data(using: .utf8)
        if let jsonData {
            var jsonDictionary = try? JSONSerialization
                .jsonObject(with: jsonData, options: []) as? [String: Any]

            jsonDictionary?["uuid"] = row[TasksColumns.uuid]

            guard let jsonDictionary else {
                throw TCError.genericError("jsonDictionary was null")
            }

            let updatedJsonData = try? JSONSerialization.data(withJSONObject: jsonDictionary, options: [])

            guard let updatedJsonData else {
                throw TCError.genericError("updatedJsonData was null")
            }

            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .secondsSince1970

            let taskObject = try? jsonDecoder.decode(TCTask.self, from: updatedJsonData)

            return taskObject
        }
        return nil
    }

    public func togglePendingTasksStatus(uuids: Set<String>) throws {
        let tasks = Table("tasks")
        let query = tasks.filter(uuids.contains(TasksColumns.uuid))
        let queryTasks = try dbConnection?.prepare(query)
        guard let queryTasks else {
            throw TCError.genericError("Query was null")
        }
        for task in queryTasks {
            if let taskObject = try parseTask(row: task) {
                let newStatus: TCTask.Status = taskObject.status == .pending ? .completed : .pending
                var newTask = taskObject
                newTask.status = newStatus
                try updateTask(newTask)
            }
        }
    }

    public func updatePendingTasks(_ uuids: Set<String>, withStatus newStatus: TCTask.Status) throws {
        let tasks = Table("tasks")

        let query = tasks.filter(uuids.contains(TasksColumns.uuid))
        let queryTasks = try dbConnection?.prepare(query)
        guard let queryTasks else {
            throw TCError.genericError("Query was null")
        }
        for task in queryTasks {
            let newData = task[TasksColumns.data].replacingOccurrences(
                of: TCTask.Status.pending.rawValue,
                with: newStatus.rawValue
            )
            try dbConnection?.run(query.update(TasksColumns.data <- newData))
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    public func updateTask(_ task: TCTask) throws {
        let jsonData = try JSONEncoder().encode(task)
        var jsonDictionary = try? JSONSerialization
            .jsonObject(with: jsonData, options: []) as? [String: Any]

        let modifiedDate = String(Date().timeIntervalSince1970.rounded())

        jsonDictionary?["modified"] = modifiedDate

        let tasks = Table("tasks")
        let query = tasks.filter(TasksColumns.uuid == task.uuid.lowercased())
        let queryTasks = try dbConnection?.prepare(query)

        guard let queryTasks else {
            throw TCError.genericError("Query was null")
        }

        for task in queryTasks {
            let oldData = task[TasksColumns.data].data(using: .utf8)
            guard let oldData else {
                throw TCError.genericError("oldData was null")
            }
            let oldJsonDictionary = try? JSONSerialization
                .jsonObject(with: oldData, options: []) as? [String: Any]

            guard let oldJsonDictionary, let jsonDictionary else {
                throw TCError.genericError("jsonDictionary was null")
            }
            let mergedJsonDictionary = oldJsonDictionary.merging(jsonDictionary) { _, new in new }

            let updatedJsonData = try? JSONSerialization.data(withJSONObject: mergedJsonDictionary, options: [])

            guard let updatedJsonData else {
                throw TCError.genericError("updatedJsonData was null")
            }
            let jsonString = String(data: updatedJsonData, encoding: .utf8)
            guard let jsonString else {
                throw TCError.genericError("jsonString was null")
            }
            try dbConnection?.run(query.update(TasksColumns.data <- jsonString))
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    public func createTask(_ task: TCTask) throws {
        let jsonData = try JSONEncoder().encode(task)
        var jsonDictionary = try? JSONSerialization
            .jsonObject(with: jsonData, options: []) as? [String: Any]

        let createdDate = String(Date().timeIntervalSince1970.rounded())

        jsonDictionary?["modified"] = createdDate
        jsonDictionary?["entry"] = createdDate

        guard let jsonDictionary else {
            throw TCError.genericError("jsonDictionary was null")
        }

        let updatedJsonData = try? JSONSerialization.data(withJSONObject: jsonDictionary, options: [])

        guard let updatedJsonData else {
            throw TCError.genericError("updatedJsonData was null")
        }

        let jsonString = String(data: updatedJsonData, encoding: .utf8)
        guard let jsonString else {
            throw TCError.genericError("jsonString was null")
        }
        let tasks = Table("tasks")
        try dbConnection?.run(tasks.insert(
            TasksColumns.uuid <- task.uuid.lowercased(),
            TasksColumns.data <- jsonString
        ))
        WidgetCenter.shared.reloadAllTimelines()
    }
}
