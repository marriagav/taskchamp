import Foundation

public enum TCSyntheticTag: String, CaseIterable {
    case overdue = "OVERDUE"
    case due = "DUE"
    case dueToday = "DUETODAY"
    case today = "TODAY"
    case yesterday = "YESTERDAY"
    case tomorrow = "TOMORROW"
    case week = "WEEK"
    case month = "MONTH"
    case quarter = "QUARTER"
    case year = "YEAR"
    case annotated = "ANNOTATED"
    case tagged = "TAGGED"
    case priority = "PRIORITY"
    case project = "PROJECT"
    case parent = "PARENT"
    case child = "CHILD"
    case ready = "READY"
    case scheduled = "SCHEDULED"
    case until = "UNTIL"
    case latest = "LATEST"

    public func toTCTag() -> TCTag {
        TCTag(name: rawValue)
    }

    // swiftlint:disable:next cyclomatic_complexity
    public func applies(
        to task: TCTask,
        hasAnnotations: Bool = false,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        switch self {
        case .overdue:
            guard let due = task.due else { return false }
            return due < now
        case .due:
            guard
                let due = task.due,
                let sevenDaysFromNow = calendar.date(byAdding: .day, value: 7, to: now)
            else {
                return false
            }
            return due <= sevenDaysFromNow
        case .dueToday, .today:
            guard let due = task.due else { return false }
            return calendar.isDateInToday(due)
        case .yesterday:
            guard let due = task.due else { return false }
            return calendar.isDateInYesterday(due)
        case .tomorrow:
            guard let due = task.due else { return false }
            return calendar.isDateInTomorrow(due)
        case .week:
            guard let due = task.due else { return false }
            return calendar.isDate(due, equalTo: now, toGranularity: .weekOfYear)
        case .month:
            guard let due = task.due else { return false }
            return calendar.isDate(due, equalTo: now, toGranularity: .month)
        case .quarter:
            guard let due = task.due else { return false }
            let dueQuarter = (calendar.component(.month, from: due) - 1) / 3
            let nowQuarter = (calendar.component(.month, from: now) - 1) / 3
            return calendar.component(.year, from: due) == calendar.component(.year, from: now)
                && dueQuarter == nowQuarter
        case .year:
            guard let due = task.due else { return false }
            return calendar.isDate(due, equalTo: now, toGranularity: .year)
        case .annotated:
            return hasAnnotations
        case .tagged:
            return task.tags?.contains { !$0.isSynthetic() } ?? false
        case .priority:
            guard let priority = task.priority else { return false }
            return priority != .none
        case .project:
            guard let project = task.project else { return false }
            return !project.isEmpty
        case .parent:
            return task.status == .recurring
        case .child:
            return task.recur != nil && task.status != .recurring
        case .ready:
            guard task.status == .pending else { return false }
            let existingTagNames = Set((task.tags ?? []).map { $0.name })
            return !existingTagNames.contains("BLOCKED") && !existingTagNames.contains("WAITING")
        case .scheduled:
            return task.scheduled != nil
        case .until:
            return task.until != nil
        case .latest:
            // LATEST is collection-dependent; see TCTask.markLatestTask(in:).
            return false
        }
    }
}
