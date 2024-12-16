import Foundation
import UserNotifications

public class NotificationService {
    public static let shared = NotificationService()
    var viewURL: URL?
    let center = UNUserNotificationCenter.current()

    private init() {}

    public static func defaultRequestCallback(success: Bool, error: (any Error)?) {
        if success {
            print("Notification Authorization granted")
        } else if let error = error {
            print(error.localizedDescription)
        }
    }

    public func requestAuthorization(
        completionHandler: @escaping (Bool, (any Error)?)
            -> Void = defaultRequestCallback
    ) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [
                .alert,
                .badge,
                .sound
            ],
            completionHandler: completionHandler
        )
    }

    public func removeAllNotifications() {
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }

    public func removeNotifications(for uuids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: uuids)
    }

    public func deleteReminderForTask(task: TCTask) {
        center.removePendingNotificationRequests(withIdentifiers: [task.uuid])
    }

    public func createReminderForTasks(tasks: [TCTask]) {
        tasks.forEach { createReminderForTask(task: $0) }
    }

    public func createReminderForTask(task: TCTask) {
        guard let due = task.due else {
            return
        }
        let curDateComponents = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: due)

        let content = UNMutableNotificationContent()

        content.title = task.description
        content.body = task.localDateShort
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: curDateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: task.uuid,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [task.uuid])
        center.add(request)
    }
}
