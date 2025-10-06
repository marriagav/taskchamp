import Foundation

public class FileService {
    public static let shared = FileService()

    private init() {}

    public func isICloudAvailable() -> Bool {
        FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
    }

    func createDirectoryIfNeeded(url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(
                    at: url,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                print("Error creating directory: \(error)")
            }
        }
    }

    public func getDestinationPathForICloudServer() throws -> String {
        let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)

        guard let containerURL else {
            throw TCError.genericError("No iCloud container URL")
        }

        let documentsURL = containerURL.appendingPathComponent("Documents")
        let taskDirectory = documentsURL.appendingPathComponent("taskchamp")

        createDirectoryIfNeeded(url: documentsURL)
        createDirectoryIfNeeded(url: taskDirectory)

        return taskDirectory.path
    }

    public func getSelectedSyncType() -> TaskchampionService.SyncType? {
        let value: TaskchampionService.SyncType? = UserDefaultsManager.shared.getDecodedValue(forKey: .selectedSyncType)
        return value
    }

    public func getDestinationPathForLocalReplica(syncType: TaskchampionService.SyncType) throws -> String {
        switch syncType {
        case .local:
            return try getDestinationPathForLocal()
        default:
            return try getDestinationPathForRemote()
        }
    }

    public func getDestinationPathForLocalReplica() throws -> String {
        let syncType = getSelectedSyncType()
        switch syncType {
        case .local:
            return try getDestinationPathForLocal()
        default:
            return try getDestinationPathForRemote()
        }
    }

    public func getDestinationPathForLocal() throws -> String {
        let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)

        guard let containerURL else {
            throw TCError.genericError("No iCloud container URL")
        }

        let documentsURL = containerURL.appendingPathComponent("Documents")
        let taskDirectory = documentsURL.appendingPathComponent("taskchamp")

        createDirectoryIfNeeded(url: documentsURL)
        createDirectoryIfNeeded(url: taskDirectory)

        return taskDirectory.path
    }

    public func getDestinationPathForRemote() throws -> String {
        guard let containerURL = FileManager
            .default
            .containerURL(
                forSecurityApplicationGroupIdentifier:
                UserDefaultsManager.suiteName
            ) else
        // swiftlint:disable:next opening_brace
        {
            throw TCError.genericError("No container URL")
        }

        let taskDirectory = containerURL.appendingPathComponent("taskchamp")

        createDirectoryIfNeeded(url: taskDirectory)

        return taskDirectory.path
    }

    public func getDestinationPathForLegacy() throws -> String? {
        let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)

        guard let containerURL else {
            throw TCError.genericError("No iCloud container URL")
        }

        let documentsURL = containerURL.appendingPathComponent("Documents")
        let taskDirectory = documentsURL.appendingPathComponent("task")
        let destinationPath = taskDirectory.appendingPathComponent("taskchampion.sqlite3")

        createDirectoryIfNeeded(url: documentsURL)
        createDirectoryIfNeeded(url: taskDirectory)

        let exists = FileManager.default.fileExists(atPath: destinationPath.path)

        if !exists { return nil }
        return destinationPath.path
    }

    public func copyLegacyDbToICloud() throws {
        let legacyDestinationPath = try getDestinationPathForLegacy()
        guard let legacyDestinationPath else { return }

        let newDestinationPath = try getDestinationPathForLocal()
        let url = URL(string: newDestinationPath)?.appendingPathComponent("taskchampion.sqlite3")
        guard let url else {
            throw TCError.genericError("No iCloud container URL")
        }

        let exists = FileManager.default.fileExists(atPath: url.path)
        if exists { return }

        try FileManager.default.copyItem(
            atPath: legacyDestinationPath,
            toPath: url.path
        )
    }

    public func copyItemToBundle(atPath: String) throws -> String {
        guard let containerURL = FileManager
            .default
            .containerURL(
                forSecurityApplicationGroupIdentifier:
                UserDefaultsManager.suiteName
            ) else
        // swiftlint:disable:next opening_brace
        {
            throw TCError.genericError("No container URL")
        }

        let taskDirectory = containerURL.appendingPathComponent("taskchamp")
        createDirectoryIfNeeded(url: taskDirectory)

        let fileName = getFileNameFromPath(path: atPath)
        let url = URL(fileURLWithPath: taskDirectory.path).appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }

        try FileManager.default.copyItem(atPath: atPath, toPath: url.path)
        return url.path
    }

    public func copyItem(atPath: String, toPath: String) throws {
        try FileManager.default.copyItem(atPath: atPath, toPath: toPath)
    }

    public func getFileNameFromPath(path: String) -> String {
        let url = URL(fileURLWithPath: path)
        return url.lastPathComponent
    }

    public func saveObsidianSettings(url: URL?) throws {
        guard let url else {
            UserDefaultsManager.shared.set(value: "", forKey: .taskNotesFolderPath)
            UserDefaultsManager.shared.set(value: "", forKey: .obsidianVaultName)
            UserDefaultsManager.shared.set(value: "", forKey: .tasksFolderPath)
            return
        }

        UserDefaultsManager.shared.set(value: url.path, forKey: .taskNotesFolderPath)

        let components = url.pathComponents

        let hasObsidian = components.contains { $0.localizedCaseInsensitiveContains("obsidian") }

        if hasObsidian, let documentsIndex = components.firstIndex(of: "Documents") {
            let vault = components[documentsIndex + 1]
            let remaining = components.suffix(from: documentsIndex + 2)
            let subpath = remaining.joined(separator: "/")

            UserDefaultsManager.shared.set(value: vault, forKey: .obsidianVaultName)
            UserDefaultsManager.shared.set(value: subpath, forKey: .tasksFolderPath)
        }

    }
}
