import Foundation

enum TasksHelper {
    static func sortTasks(_ tasks: inout [Task]) {
        tasks.sort {
            if let date = $0.due {
                if let otherDate = $1.due {
                    return date < otherDate
                } else {
                    return true
                }
            } else {
                if let priority = $0.priority {
                    if let otherPriority = $1.priority {
                        return priority > otherPriority
                    } else {
                        return true
                    }
                } else {
                    return false
                }
            }
        }
    }
}
