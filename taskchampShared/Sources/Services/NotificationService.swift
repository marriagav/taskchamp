import Foundation
import UserNotifications

public class NotificationService: NSObject {
    public static let shared = NotificationService()
    let center = UNUserNotificationCenter.current()

    override private init() {
        super.init()
        center.delegate = self
    }

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

    public func createReminderForTasks(tasks: [TCTask]) async {
        let notifTaskIds = await center.pendingNotificationRequests().map { $0.identifier }
        for task in tasks where !notifTaskIds.contains(task.uuid) && task.due != nil && (task.due ?? Date()) > Date() {
            createReminderForTask(task: task)
        }
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
        content.userInfo = ["deepLink": task.url.description]

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

// MARK: UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    @MainActor
    public func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if let deepLink = response.notification.request.content.userInfo["deepLink"] as? String {
            let viewURL = URL(string: deepLink)
            NotificationCenter.default.post(name: .TCTappedDeepLinkNotification, object: viewURL)
        }
    }
}

public extension NSNotification.Name {
    static let TCTappedDeepLinkNotification = NSNotification.Name("TCTappedDeepLinkNotification")
}
