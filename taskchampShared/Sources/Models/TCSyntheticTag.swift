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
    case waiting = "WAITING"
    case blocked = "BLOCKED"

    public func toTCTag() -> TCTag {
        TCTag(name: rawValue)
    }

    public func applies(
        to task: TCTask,
        hasAnnotations: Bool = false,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        switch self {
        case .overdue, .due, .dueToday, .today, .yesterday,
            .tomorrow, .week, .month, .quarter, .year:
            return appliesDueDateCase(for: task, now: now, calendar: calendar)
        case .annotated:
            return hasAnnotations
        case .tagged:
            return task.tags?.contains { !$0.isSynthetic() } ?? false
        case .priority:
            return (task.priority ?? .none) != TCTask.Priority.none
        case .project:
            return !(task.project ?? "").isEmpty
        case .parent:
            return task.status == .recurring
        case .child:
            return task.recur != nil && task.status != .recurring
        case .ready:
            guard task.status == .pending else { return false }
            let existingTagNames = Set((task.tags ?? []).map { $0.name })
            return !existingTagNames.contains(Self.blocked.rawValue)
                && !existingTagNames.contains(Self.waiting.rawValue)
        case .scheduled:
            return task.scheduled != nil
        case .until:
            return task.until != nil
        case .latest:
            // LATEST is collection-dependent; see TCTask.markLatestTask(in:).
            return false
        case .waiting, .blocked:
            return task.tags?.contains { $0.name == rawValue } ?? false
        }
    }

    private func appliesDueDateCase(for task: TCTask, now: Date, calendar: Calendar) -> Bool {
        guard let due = task.due else { return false }
        switch self {
        case .overdue:
            return due < now
        case .due:
            let lookaheadDays: Int = UserDefaultsManager.standard.getValue(forKey: .dueLookaheadDays) ?? 7
            guard let lookaheadDate = calendar.date(byAdding: .day, value: max(1, lookaheadDays), to: now)
            else { return false }
            return due <= lookaheadDate
        case .dueToday, .today:
            return calendar.isDateInToday(due)
        case .yesterday:
            return calendar.isDateInYesterday(due)
        case .tomorrow:
            return calendar.isDateInTomorrow(due)
        case .week:
            return calendar.isDate(due, equalTo: now, toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(due, equalTo: now, toGranularity: .month)
        case .quarter:
            let dueQuarter = (calendar.component(.month, from: due) - 1) / 3
            let nowQuarter = (calendar.component(.month, from: now) - 1) / 3
            return calendar.component(.year, from: due) == calendar.component(.year, from: now)
                && dueQuarter == nowQuarter
        case .year:
            return calendar.isDate(due, equalTo: now, toGranularity: .year)
        default:
            return false
        }
    }
}
