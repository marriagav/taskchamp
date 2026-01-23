import Foundation

public enum TCUserDefaults: String {
    case selectedFilter
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

    // Reminders Capture
    case remindersCaptureEnabled
    case remindersCaptureListId
    case remindersCaptureListName
    case remindersCapturePostImportAction
    case remindersLastImportedIds
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
