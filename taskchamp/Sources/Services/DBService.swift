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
                let jsonObject = task[TasksColumns.data]
                let jsonData = jsonObject.data(using: .utf8)
                if let jsonData {
                    var jsonDictionary = try? JSONSerialization
                        .jsonObject(with: jsonData, options: []) as? [String: Any]

                    jsonDictionary?["uuid"] = task[TasksColumns.uuid]

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

                    if let taskObject {
                        taskObjects.append(taskObject)
                    }
                }
            }
            return taskObjects
        } catch {
            throw error
        }
    }

    public func completeTask(id: String) throws {
        do {
            let tasks = Table("tasks")
            let query = tasks.filter(TasksColumns.uuid == id)
            try dbConnection?.run(query.update(TasksColumns.data <- TasksColumns.data.replace("pending", with: "done")))
        } catch {
            throw error
        }
    }
}
