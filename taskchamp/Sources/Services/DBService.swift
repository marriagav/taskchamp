import Foundation
import SQLite

class DBService {
    enum TasksColumns {
        static let uuid = Expression<String>("uuid")
        static let data = Expression<String>("data")
    }

    static let shared = DBService()
    private var dbConnection: Connection?

    private init() {}

    public func setDbUrl(_ path: String) {
        do {
            dbConnection = try Connection(path)
        } catch {
            print(error)
        }
    }

    public func getPendingTasks() throws -> [Task] {
        var taskObjects: [Task] = []
        do {
            let tasks = Table("tasks")
            let query = tasks.select(TasksColumns.data, TasksColumns.uuid)
                .filter(TasksColumns.data.like("%\"status\":\"pending\"%"))
            let queryTasks = try dbConnection?.prepare(query)
            guard let queryTasks else {
                throw TCError.genericError("Query was null")
            }
            for task in queryTasks {
                if let taskObject = try parseTask(row: task) {
                    taskObjects.append(taskObject)
                }
            }
            TasksHelper.sortTasks(&taskObjects)
            return taskObjects
        } catch {
            throw error
        }
    }

    private func parseTask(row: Row) throws -> Task? {
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

            let taskObject = try? jsonDecoder.decode(Task.self, from: updatedJsonData)

            return taskObject
        }
        return nil
    }

    func updatePendingTask(_ uuid: String, withStatus newStatus: Task.Status) throws {
        do {
            let tasks = Table("tasks")

            let query = tasks.filter(TasksColumns.uuid == uuid)
            let queryTasks = try dbConnection?.prepare(query)
            guard let queryTasks else {
                throw TCError.genericError("Query was null")
            }
            for task in queryTasks {
                let newData = task[TasksColumns.data].replacingOccurrences(
                    of: Task.Status.pending.rawValue,
                    with: newStatus.rawValue
                )
                try dbConnection?.run(query.update(TasksColumns.data <- newData))
            }
        } catch {
            throw error
        }
    }
}
