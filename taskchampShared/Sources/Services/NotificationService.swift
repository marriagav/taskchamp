import Foundation
import UserNotifications

/// Represents the authorization status for critical alerts
public enum CriticalAlertAuthorizationStatus: String {
    case notDetermined
    case authorized
    case denied

    public var displayName: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        }
    }
}

public class NotificationService: NSObject {
    public static let shared = NotificationService()
    let center = UNUserNotificationCenter.current()

    /// Cached authorization status for critical alerts
    public private(set) var criticalAlertStatus: CriticalAlertAuthorizationStatus = .notDetermined

    /// Global setting to enable/disable critical alerts
    public var criticalAlertsEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "criticalAlertsEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "criticalAlertsEnabled")
        }
    }

    /// Default volume preset for new critical alerts
    public var defaultCriticalAlertVolumePreset: TCCriticalAlertVolumePreset {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: "defaultCriticalAlertVolumePreset"),
                let preset = TCCriticalAlertVolumePreset(rawValue: rawValue) {
                return preset
            }
            return .half
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "defaultCriticalAlertVolumePreset")
        }
    }

    override private init() {
        super.init()
        center.delegate = self
        // Initialize critical alerts as enabled by default
        if UserDefaults.standard.object(forKey: "criticalAlertsEnabled") == nil {
            criticalAlertsEnabled = true
        }
        // Check current authorization status
        Task {
            await updateCriticalAlertStatus()
        }
    }

    public static func defaultRequestCallback(success: Bool, error: (any Error)?) {
        if success {
            print("Notification Authorization granted")
        } else if let error = error {
            print(error.localizedDescription)
        }
    }

    /// Updates the cached critical alert authorization status
    @MainActor
    public func updateCriticalAlertStatus() async {
        let settings = await center.notificationSettings()
        switch settings.criticalAlertSetting {
        case .enabled:
            criticalAlertStatus = .authorized
        case .disabled:
            criticalAlertStatus = .denied
        case .notSupported:
            criticalAlertStatus = .notDetermined
        @unknown default:
            criticalAlertStatus = .notDetermined
        }
        NotificationCenter.default.post(
            name: .TCCriticalAlertAuthorizationChanged,
            object: criticalAlertStatus
        )
    }

    /// Requests authorization for notifications including critical alerts
    public func requestAuthorization(
        completionHandler: @escaping (Bool, (any Error)?)
            -> Void = defaultRequestCallback
    ) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [
                .alert,
                .badge,
                .sound,
                .criticalAlert
            ],
        ) { [weak self] success, error in
            completionHandler(success, error)
            Task { @MainActor in
                await self?.updateCriticalAlertStatus()
            }
        }
    }

    /// Requests authorization for critical alerts specifically
    public func requestCriticalAlertAuthorization(
        completionHandler: @escaping (Bool, (any Error)?) -> Void = defaultRequestCallback
    ) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [
                .alert,
                .badge,
                .sound,
                .criticalAlert
            ]
        ) { [weak self] success, error in
            completionHandler(success, error)
            Task { @MainActor in
                await self?.updateCriticalAlertStatus()
            }
        }
    }

    /// Checks if critical alerts can be used (authorized and enabled)
    public var canUseCriticalAlerts: Bool {
        criticalAlertStatus == .authorized && criticalAlertsEnabled
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
        content.userInfo = ["deepLink": task.url.description]

        // Configure sound and interruption level based on critical alert settings
        if task.hasCriticalAlert && canUseCriticalAlerts {
            let volume = task.criticalAlert?.effectiveVolume ?? 1.0
            content.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: volume)
            content.interruptionLevel = .critical
        } else {
            content.sound = UNNotificationSound.default
            content.interruptionLevel = .timeSensitive
        }

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
        if let deepLink = response.notification.request.content.userInfo["deepLink"] as? String {
            let viewURL = URL(string: deepLink)
            NotificationCenter.default.post(name: .TCTappedDeepLinkNotification, object: viewURL)
        }
    }
}

public extension NSNotification.Name {
    static let TCTappedDeepLinkNotification = NSNotification.Name("TCTappedDeepLinkNotification")
    static let TCCriticalAlertAuthorizationChanged = NSNotification.Name("TCCriticalAlertAuthorizationChanged")
}
