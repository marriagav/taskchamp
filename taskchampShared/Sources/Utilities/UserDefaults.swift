import Foundation

public enum TCUserDefaults: String {
    case selectedFilter
    case savedFilters
    case sortType

    case taskNoteFolderBookmark
    case taskNotesFolderPath
    case obsidianVaultName
    case tasksFolderPath

    case selectedSyncType

    case remoteServerUrl
    case remoteServerClientId
    case remoteServerEncryptionSecret

    case gcpServerBucket
    case gcpServerCredentialPath
    case gcpServerEncryptionSecret

    case awsServerBucket
    case awsServerRegion
    case awsServerAccessKeyId
    case awsServerSecretAccessKey
    case awsServerEncryptionSecret

    case storeKitPremiumUnlocked
    case storeKitCloudSubscriptionActive

    case pendingNewTaskContent

    case suggestOnlyActiveProjects
    case taskCellLineLimit
    case dueLookaheadDays
    case hasDefaultDueTime
    case defaultDueTimeMinutes
}

public class UserDefaultsManager {
    public static let suiteName = "group.com.mav.taskchamp"
    public static let standard = UserDefaultsManager(UserDefaults.standard)
    public static let shared = UserDefaultsManager(UserDefaults(suiteName: suiteName) ?? .standard)

    private let defaults: UserDefaults

    private init(_ defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func set<T>(value: T, forKey key: TCUserDefaults) {
        defaults.set(value, forKey: key.rawValue)
    }

    public func getValue<T>(forKey key: TCUserDefaults) -> T? {
        return defaults.value(forKey: key.rawValue) as? T
    }

    public func getData(forKey key: TCUserDefaults) -> Data? {
        return defaults.data(forKey: key.rawValue)
    }

    public func setEncodableValue<T: Encodable>(_ value: T, forKey key: TCUserDefaults) throws {
        let data = try JSONEncoder().encode(value)
        set(value: data, forKey: key)
    }

    public func getDecodedValue<T: Decodable>(forKey key: TCUserDefaults) -> T? {
        guard let data = getData(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    public func remove(forKey key: TCUserDefaults) {
        defaults.removeObject(forKey: key.rawValue)
    }

    public func clearAll() {
        if let appDomain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: appDomain)
        }
    }
}

extension UserDefaultsManager {
    /// Returns a Date with the user's configured default-due-time as its hour/minute,
    /// or nil if the user has not enabled a default.
    public func defaultDueTime() -> Date? {
        let hasDefault: Bool = getValue(forKey: .hasDefaultDueTime) ?? false
        guard hasDefault else { return nil }
        let minutes: Int = getValue(forKey: .defaultDueTimeMinutes) ?? (9 * 60)
        return Calendar.current.date(
            bySettingHour: minutes / 60,
            minute: minutes % 60,
            second: 0,
            of: Date()
        )
    }

    /// If `date` has a midnight time component and the user has a default due time
    /// configured, returns the same date with the default hour/minute applied.
    public func applyDefaultDueTimeIfMidnight(to date: Date?) -> Date? {
        guard let date else { return nil }
        let calendar = Calendar.current
        let comp = calendar.dateComponents([.hour, .minute], from: date)
        guard comp.hour == 0, comp.minute == 0, let defaultTime = defaultDueTime() else { return date }
        let timeComp = calendar.dateComponents([.hour, .minute], from: defaultTime)
        var dateComp = calendar.dateComponents([.year, .month, .day], from: date)
        dateComp.hour = timeComp.hour
        dateComp.minute = timeComp.minute
        return calendar.date(from: dateComp)
    }
}
