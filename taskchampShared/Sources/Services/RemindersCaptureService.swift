import EventKit
import Foundation

/// Represents the authorization status for reminders access
public enum RemindersAuthorizationStatus: String {
    case notDetermined
    case authorized
    case denied
    case restricted

    public var displayName: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        }
    }
}

/// Action to take after importing a reminder
public enum ReminderPostImportAction: String, Codable, CaseIterable {
    case markComplete
    case delete

    public var displayName: String {
        switch self {
        case .markComplete:
            return "Mark Complete"
        case .delete:
            return "Delete from Reminders"
        }
    }
}

/// Represents an Apple Reminders list for selection
public struct RemindersList: Identifiable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let color: CGColor?

    public init(from calendar: EKCalendar) {
        id = calendar.calendarIdentifier
        title = calendar.title
        color = calendar.cgColor
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Result of an import operation
public struct RemindersImportResult {
    public let importedCount: Int
    public let failedCount: Int
    public let errors: [Error]

    public init(importedCount: Int, failedCount: Int, errors: [Error]) {
        self.importedCount = importedCount
        self.failedCount = failedCount
        self.errors = errors
    }
}

/// Service for capturing tasks from Apple Reminders
public class RemindersCaptureService {
    public static let shared = RemindersCaptureService()

    private let eventStore = EKEventStore()
    private var importedReminderIds: Set<String> = []

    /// Cached authorization status
    public private(set) var authorizationStatus: RemindersAuthorizationStatus = .notDetermined

    /// Whether reminders capture is enabled
    public var isEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: TCUserDefaults.remindersCaptureEnabled.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: TCUserDefaults.remindersCaptureEnabled.rawValue)
            NotificationCenter.default.post(name: .TCRemindersCaptureSettingsChanged, object: nil)
        }
    }

    /// The ID of the selected capture list
    public var selectedListId: String? {
        get {
            UserDefaults.standard.string(forKey: TCUserDefaults.remindersCaptureListId.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: TCUserDefaults.remindersCaptureListId.rawValue)
            NotificationCenter.default.post(name: .TCRemindersCaptureSettingsChanged, object: nil)
        }
    }

    /// The name of the selected capture list (cached for display)
    public var selectedListName: String? {
        get {
            UserDefaults.standard.string(forKey: TCUserDefaults.remindersCaptureListName.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: TCUserDefaults.remindersCaptureListName.rawValue)
        }
    }

    /// Action to take after importing a reminder
    public var postImportAction: ReminderPostImportAction {
        get {
            if let rawValue = UserDefaults.standard
                .string(forKey: TCUserDefaults.remindersCapturePostImportAction.rawValue),
                let action = ReminderPostImportAction(rawValue: rawValue)
            {
                return action
            }
            return .markComplete
        }
        set {
            UserDefaults.standard.set(
                newValue.rawValue,
                forKey: TCUserDefaults.remindersCapturePostImportAction.rawValue
            )
        }
    }

    private init() {
        loadImportedReminderIds()
        Task {
            await updateAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Updates the cached authorization status
    @MainActor
    public func updateAuthorizationStatus() async {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .fullAccess, .authorized:
            authorizationStatus = .authorized
        case .denied:
            authorizationStatus = .denied
        case .restricted, .writeOnly:
            authorizationStatus = .restricted
        @unknown default:
            authorizationStatus = .notDetermined
        }
        NotificationCenter.default.post(
            name: .TCRemindersAuthorizationChanged,
            object: authorizationStatus
        )
    }

    /// Requests authorization to access reminders
    @MainActor
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToReminders()
            await updateAuthorizationStatus()
            return granted
        } catch {
            print("Failed to request reminders authorization: \(error)")
            await updateAuthorizationStatus()
            return false
        }
    }

    // MARK: - Lists

    /// Gets all available reminder lists
    public func getAvailableLists() -> [RemindersList] {
        guard authorizationStatus == .authorized else {
            return []
        }
        let calendars = eventStore.calendars(for: .reminder)
        return calendars.map { RemindersList(from: $0) }
    }

    /// Gets the selected capture list
    public func getSelectedList() -> RemindersList? {
        guard let listId = selectedListId,
              let calendar = eventStore.calendar(withIdentifier: listId) else
        {
            return nil
        }
        return RemindersList(from: calendar)
    }

    /// Validates that the selected list still exists
    public func validateSelectedList() -> Bool {
        guard let listId = selectedListId else {
            return false
        }
        return eventStore.calendar(withIdentifier: listId) != nil
    }

    // MARK: - Import

    /// Gets the count of incomplete reminders in the selected list
    @MainActor
    public func getIncompleteRemindersCount() async -> Int {
        guard isEnabled,
              authorizationStatus == .authorized,
              let listId = selectedListId,
              let calendar = eventStore.calendar(withIdentifier: listId) else
        {
            return 0
        }

        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: [calendar]
        )

        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                let count = reminders?.filter { !self.importedReminderIds.contains($0.calendarItemIdentifier) }
                    .count ?? 0
                continuation.resume(returning: count)
            }
        }
    }

    /// Fetches incomplete reminders from the selected list
    private func fetchIncompleteReminders() async -> [EKReminder] {
        guard isEnabled,
              authorizationStatus == .authorized,
              let listId = selectedListId,
              let calendar = eventStore.calendar(withIdentifier: listId) else
        {
            return []
        }

        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: [calendar]
        )

        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    /// Imports reminders from the selected list into Taskchamp
    @MainActor
    public func importReminders() async throws -> RemindersImportResult {
        guard isEnabled else {
            return RemindersImportResult(importedCount: 0, failedCount: 0, errors: [])
        }

        guard authorizationStatus == .authorized else {
            throw RemindersCaptureError.notAuthorized
        }

        guard validateSelectedList() else {
            // Clear the invalid list selection
            selectedListId = nil
            selectedListName = nil
            throw RemindersCaptureError.listNotFound
        }

        let reminders = await fetchIncompleteReminders()
        var importedCount = 0
        var failedCount = 0
        var errors: [Error] = []

        for reminder in reminders {
            // Skip already imported reminders
            if importedReminderIds.contains(reminder.calendarItemIdentifier) {
                continue
            }

            do {
                // Create TCTask from reminder
                let task = createTask(from: reminder)

                // Save to Taskchampion
                try TaskchampionService.shared.createTask(task) {}

                // Create notification if task has a due date
                if task.due != nil {
                    NotificationService.shared.createReminderForTask(task: task)
                }

                // Mark as imported
                importedReminderIds.insert(reminder.calendarItemIdentifier)

                // Handle post-import action
                try await handlePostImportAction(for: reminder)

                importedCount += 1
            } catch {
                failedCount += 1
                errors.append(error)
            }
        }

        // Save imported IDs
        saveImportedReminderIds()

        // Post notification about import completion
        NotificationCenter.default.post(
            name: .TCRemindersImportCompleted,
            object: RemindersImportResult(importedCount: importedCount, failedCount: failedCount, errors: errors)
        )

        return RemindersImportResult(importedCount: importedCount, failedCount: failedCount, errors: errors)
    }

    /// Creates a TCTask from an EKReminder
    private func createTask(from reminder: EKReminder) -> TCTask {
        let uuid = UUID().uuidString

        // Map priority (EKReminder uses 0=none, 1-4=high, 5=medium, 6-9=low)
        var priority: TCTask.Priority? = nil
        if reminder.priority > 0 {
            if reminder.priority <= 4 {
                priority = .high
            } else if reminder.priority == 5 {
                priority = .medium
            } else {
                priority = .low
            }
        }

        // Get due date from dueDateComponents
        var dueDate: Date? = nil
        if let dueDateComponents = reminder.dueDateComponents {
            dueDate = Calendar.current.date(from: dueDateComponents)
        }

        // Build description - use title, append notes if present
        var description = reminder.title ?? "Imported Reminder"
        if let notes = reminder.notes, !notes.isEmpty {
            // Store notes as part of description with separator
            description += " | \(notes)"
        }

        // Note if reminder has recurrence (we don't import recurrence rules)
        if reminder.hasRecurrenceRules {
            description += " [recurring]"
        }

        return TCTask(
            uuid: uuid,
            project: nil,
            description: description,
            status: .pending,
            priority: priority,
            due: dueDate,
            obsidianNote: nil,
            noteAnnotationKey: nil,
            tags: nil,
            locationReminder: nil,
            criticalAlert: nil
        )
    }

    /// Handles the post-import action for a reminder
    private func handlePostImportAction(for reminder: EKReminder) async throws {
        switch postImportAction {
        case .markComplete:
            reminder.isCompleted = true
            reminder.completionDate = Date()
            try eventStore.save(reminder, commit: true)
        case .delete:
            try eventStore.remove(reminder, commit: true)
        }
    }

    // MARK: - Persistence

    private func loadImportedReminderIds() {
        if let data = UserDefaults.standard.data(forKey: TCUserDefaults.remindersLastImportedIds.rawValue),
           let ids = try? JSONDecoder().decode(Set<String>.self, from: data)
        {
            importedReminderIds = ids
        }
    }

    private func saveImportedReminderIds() {
        if let data = try? JSONEncoder().encode(importedReminderIds) {
            UserDefaults.standard.set(data, forKey: TCUserDefaults.remindersLastImportedIds.rawValue)
        }
    }

    /// Clears the list of imported reminder IDs (useful for debugging or reset)
    public func clearImportedIds() {
        importedReminderIds.removeAll()
        saveImportedReminderIds()
    }

    // MARK: - Configuration

    /// Selects a list for capture
    public func selectList(_ list: RemindersList) {
        selectedListId = list.id
        selectedListName = list.title
    }

    /// Clears the list selection
    public func clearListSelection() {
        selectedListId = nil
        selectedListName = nil
    }

    /// Whether capture is properly configured
    public var isConfigured: Bool {
        isEnabled && selectedListId != nil && authorizationStatus == .authorized
    }
}

// MARK: - Errors

public enum RemindersCaptureError: LocalizedError {
    case notAuthorized
    case listNotFound
    case importFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Reminders access not authorized"
        case .listNotFound:
            return "Selected reminders list no longer exists"
        case let .importFailed(underlying):
            return "Failed to import reminder: \(underlying.localizedDescription)"
        }
    }
}

// MARK: - Notifications

public extension NSNotification.Name {
    static let TCRemindersAuthorizationChanged = NSNotification.Name("TCRemindersAuthorizationChanged")
    static let TCRemindersCaptureSettingsChanged = NSNotification.Name("TCRemindersCaptureSettingsChanged")
    static let TCRemindersImportCompleted = NSNotification.Name("TCRemindersImportCompleted")
}
