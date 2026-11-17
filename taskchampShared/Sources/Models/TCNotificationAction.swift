import Foundation
import UserNotifications

/// Long-press actions on a task reminder. "Remind" actions only show the reminder again later;
/// "postpone" actions change the task's due date.
public enum TCNotificationAction: String, CaseIterable {
    case complete = "TC_TASK_COMPLETE"
    case remindInOneHour = "TC_TASK_REMIND_1H"
    case remindTomorrow = "TC_TASK_REMIND_1D"
    case postponeOneHour = "TC_TASK_POSTPONE_1H"
    case postponeTomorrow = "TC_TASK_POSTPONE_1D"

    public static let categoryIdentifier = "TC_TASK_REMINDER"
    public static let taskIdUserInfoKey = "taskId"

    public enum Kind {
        case complete
        case remind
        case postpone
    }

    public var kind: Kind {
        switch self {
        case .complete:
            return .complete
        case .remindInOneHour, .remindTomorrow:
            return .remind
        case .postponeOneHour, .postponeTomorrow:
            return .postpone
        }
    }

    public var title: String {
        switch self {
        case .complete:
            return "Complete"
        case .remindInOneHour:
            return "Remind Me in 1 Hour"
        case .remindTomorrow:
            return "Remind Me Tomorrow"
        case .postponeOneHour:
            return "Postpone 1 Hour"
        case .postponeTomorrow:
            return "Postpone to Tomorrow"
        }
    }

    var symbol: SFSymbols {
        switch kind {
        case .complete:
            return .checkmark
        case .remind:
            return .clockFill
        case .postpone:
            return .calendar
        }
    }

    var offset: DateComponents? {
        switch self {
        case .complete:
            return nil
        case .remindInOneHour, .postponeOneHour:
            return DateComponents(hour: 1)
        case .remindTomorrow, .postponeTomorrow:
            // A calendar day, not 24 hours, so the time of day stays the same across DST changes
            return DateComponents(day: 1)
        }
    }

    public func remindDate(now: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard kind == .remind, let offset else { return nil }
        return calendar.date(byAdding: offset, to: now)
    }

    public func postponedDueDate(from due: Date?, now: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard kind == .postpone, let offset else { return nil }
        return calendar.date(byAdding: offset, to: due ?? now)
    }

    /// Returns the changed task, or `nil` if the task must not change. Only pending tasks change,
    /// so a task completed on another device is not opened again.
    public func apply(to task: TCTask, now: Date = Date(), calendar: Calendar = .current) -> TCTask? {
        guard task.status == .pending else { return nil }
        var updatedTask = task
        switch kind {
        case .complete:
            updatedTask.status = .completed
        case .postpone:
            guard let due = postponedDueDate(from: task.due, now: now, calendar: calendar) else { return nil }
            updatedTask.due = due
        case .remind:
            return nil
        }
        return updatedTask
    }

    var notificationAction: UNNotificationAction {
        UNNotificationAction(
            identifier: rawValue,
            title: title,
            options: [],
            icon: UNNotificationActionIcon(systemImageName: symbol.rawValue)
        )
    }

    static var notificationCategory: UNNotificationCategory {
        UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: allCases.map(\.notificationAction),
            intentIdentifiers: [],
            options: []
        )
    }
}
