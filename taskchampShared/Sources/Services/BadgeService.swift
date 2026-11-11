import Foundation
import UserNotifications

/// Keeps the app icon badge in sync with the number of tasks matching a user-defined filter query.
///
/// The setting lives in the shared app group, so both the app and the widget extension can refresh it.
/// The widget refreshes it on every timeline reload, which keeps time-based queries like `+DUE` current
/// while the app isn't running.
@MainActor
public enum BadgeService {
    public static let defaultQuery = "+PENDING +DUE"

    public static var isEnabled: Bool {
        get { UserDefaultsManager.shared.getValue(forKey: .badgeCountEnabled) ?? false }
        set { UserDefaultsManager.shared.set(value: newValue, forKey: .badgeCountEnabled) }
    }

    public static var query: String {
        get { UserDefaultsManager.shared.getValue(forKey: .badgeCountQuery) ?? defaultQuery }
        set { UserDefaultsManager.shared.set(value: newValue, forKey: .badgeCountQuery) }
    }

    /// Whether `query` contains at least one filter term the parser understands.
    public static func isValidQuery(_ query: String) -> Bool {
        FilterParser.parse(query) != nil
    }

    /// The number of tasks matching `query`, or nil if the query is invalid or the task database isn't open.
    public static func count(for query: String) -> Int? {
        // An unparseable query would otherwise match every task, so treat it as "no count".
        guard isValidQuery(query) else { return nil }
        return try? TaskchampionService.shared.getTasks(filter: TCFilter(fullDescription: query)).count
    }

    /// Recomputes the badge from the saved setting. Clears it when the setting is off or the query is invalid.
    /// When the task database isn't open yet, the current badge is left unchanged.
    public static func refresh() async {
        let newCount: Int
        if isEnabled {
            guard isValidQuery(query) else {
                await setBadge(0)
                return
            }
            guard let count = count(for: query) else { return }
            newCount = count
        } else {
            newCount = 0
        }
        await setBadge(newCount)
    }

    private static func setBadge(_ count: Int) async {
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(count)
        } catch {
            print("Failed to set badge count: \(error)")
        }
    }
}
