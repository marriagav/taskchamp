import Foundation

public enum TasksHelper {
    public enum TCSortType: String {
        case date
        case priority
        case defaultSort
    }

    public static func sortTasksWithSortType(_ tasks: inout [TCTask], sortType: TCSortType) {
        switch sortType {
        case .date:
            sortTasksByDate(&tasks)
        case .priority:
            sortTasksByPriority(&tasks)
        case .defaultSort:
            sortTasksByDefault(&tasks)
        }
    }

    public static func sortTasksByDefault(_ tasks: inout [TCTask]) {
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

    public static func sortTasksByDate(_ tasks: inout [TCTask]) {
        tasks.sort {
            if let date = $0.due {
                if let otherDate = $1.due {
                    return date < otherDate
                } else {
                    return true
                }
            }
            return false
        }
    }

    public static func sortTasksByPriority(_ tasks: inout [TCTask]) {
        tasks.sort {
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
