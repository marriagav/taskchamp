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
            tasks.sort(by: compareByDate)
        case .priority:
            tasks.sort(by: compareByPriority)
        case .defaultSort:
            tasks.sort(by: compareByDefault)
        }
    }

    // MARK: - Comparison helpers

    /// Generic compare function that returns -1, 0, 1
    private static func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> Int {
        if lhs < rhs { return -1 }
        if lhs > rhs { return 1 }
        return 0
    }

    private static func compareOptional<T: Comparable>(_ lhs: T?, _ rhs: T?, reversed: Bool = false) -> Int {
        switch (lhs, rhs) {
        case let (left?, right?):
            let cmp = compare(left, right)
            return reversed ? -cmp : cmp
        case (_?, nil): return -1 // non-nil before nil
        case (nil, _?): return 1
        default: return 0
        }
    }

    /// Chained comparator: returns true if lhs < rhs
    private static func compareChain(_ lhs: TCTask, _ rhs: TCTask, _ rules: [(TCTask, TCTask) -> Int]) -> Bool {
        for rule in rules {
            let result = rule(lhs, rhs)
            if result < 0 { return true }
            if result > 0 { return false }
        }
        return false
    }

    // MARK: - Comparators

    private static func compareByDefault(_ lhs: TCTask, _ rhs: TCTask) -> Bool {
        return compareChain(lhs, rhs, [
            // 1. Status
            { left, right in
                if left.status == right.status { return 0 }
                if left.status == .deleted { return 1 }
                if right.status == .deleted { return -1 }
                if left.status == .completed, right.status == .pending { return 1 }
                if right.status == .completed, left.status == .pending { return -1 }
                return 0
            },
            // 2. Due date (earlier first, nil last)
            { left, right in compareOptional(left.due, right.due) },
            // 3. Priority (higher first, nil last)
            { left, right in compareOptional(left.priority, right.priority, reversed: true) },
            // 4. Description
            { left, right in compare(left.description, right.description) },
            // 5. UUID (final deterministic fallback)
            { left, right in compare(left.uuid, right.uuid) }
        ])
    }

    private static func compareByDate(_ lhs: TCTask, _ rhs: TCTask) -> Bool {
        return compareChain(lhs, rhs, [
            { left, right in
                if left.status == right.status { return 0 }
                if left.status == .deleted { return 1 }
                if right.status == .deleted { return -1 }
                if left.status == .completed, right.status == .pending { return 1 }
                if right.status == .completed, left.status == .pending { return -1 }
                return 0
            },
            { left, right in compareOptional(left.due, right.due) },
            { left, right in compare(left.description, right.description) },
            { left, right in compare(left.uuid, right.uuid) }
        ])
    }

    private static func compareByPriority(_ lhs: TCTask, _ rhs: TCTask) -> Bool {
        return compareChain(lhs, rhs, [
            { left, right in
                if left.status == right.status { return 0 }
                if left.status == .deleted { return 1 }
                if right.status == .deleted { return -1 }
                if left.status == .completed, right.status == .pending { return 1 }
                if right.status == .completed, left.status == .pending { return -1 }
                return 0
            },
            { left, right in compareOptional(left.priority, right.priority, reversed: true) },
            { left, right in compare(left.description, right.description) },
            { left, right in compare(left.uuid, right.uuid) }
        ])
    }
}
