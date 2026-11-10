import Foundation
import UserNotifications

public class NotificationService: NSObject {
    public static let shared = NotificationService()
    let center = UNUserNotificationCenter.current()

    override private init() {
        super.init()
        center.delegate = self
        center.setNotificationCategories([TCNotificationAction.notificationCategory])
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
        let capIds = uuids.map { $0.capitalized }
        center.removePendingNotificationRequests(withIdentifiers: capIds)
    }

    public func deleteReminderForTask(task: TCTask) {
        center.removePendingNotificationRequests(withIdentifiers: [task.uuid.capitalized])
    }

    public func createReminderForTasks(tasks: [TCTask]) async {
        // Create reminders again if they do not have the notification actions yet
        let notifTaskIds = await center.pendingNotificationRequests()
            .filter { $0.content.categoryIdentifier == TCNotificationAction.categoryIdentifier }
            .map { $0.identifier.lowercased() }
        let now = Date()
        for task in tasks where !notifTaskIds.contains(task.uuid.lowercased()) {
            guard let due = task.due, due > now else { continue }
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
        content.categoryIdentifier = TCNotificationAction.categoryIdentifier
        content.userInfo = [
            "deepLink": task.url.description,
            TCNotificationAction.taskIdUserInfoKey: task.uuid
        ]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: curDateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: task.uuid.capitalized,
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
        let request = response.notification.request

        if let action = TCNotificationAction(rawValue: response.actionIdentifier) {
            guard let taskId = request.content.userInfo[TCNotificationAction.taskIdUserInfoKey] as? String else {
                return
            }
            await handle(action, taskId: taskId, request: request)
            return
        }

        if let deepLink = request.content.userInfo["deepLink"] as? String {
            let viewURL = URL(string: deepLink)
            NotificationCenter.default.post(name: .TCTappedDeepLinkNotification, object: viewURL)
        }
    }

    // iOS can launch the app in the background for an action, so open the database here
    // and wait for the sync before returning
    @MainActor
    func handle(_ action: TCNotificationAction, taskId: String, request: UNNotificationRequest) async {
        if action.kind == .remind {
            if let date = action.remindDate() {
                deliverAgain(request, at: date)
            }
            return
        }

        do {
            let service = TaskchampionService.shared
            try service.setDbUrl(path: FileService.shared.getDestinationPathForLocalReplica())
            let task = try service.getTask(uuid: taskId)
            guard let updatedTask = action.apply(to: task) else {
                return
            }
            try service.updateTask(updatedTask, skipSync: true)
            if updatedTask.status == .pending {
                createReminderForTask(task: updatedTask)
            } else {
                deleteReminderForTask(task: updatedTask)
            }
            try? await service.sync()
        } catch {
            print("Failed to run notification action \(action.rawValue): \(error.localizedDescription)")
        }
    }

    func deliverAgain(_ request: UNNotificationRequest, at date: Date) {
        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            return
        }
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, date.timeIntervalSinceNow),
            repeats: false
        )
        center.add(UNNotificationRequest(identifier: request.identifier, content: content, trigger: trigger))
    }
}

public extension NSNotification.Name {
    static let TCTappedDeepLinkNotification = NSNotification.Name("TCTappedDeepLinkNotification")
}
