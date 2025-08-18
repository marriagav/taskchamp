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
        do {
            if let data = UserDefaults(suiteName: "group.com.mav.taskchamp")?.data(forKey: "selectedSyncType") {
                let res = try JSONDecoder().decode(TaskchampionService.SyncType.self, from: data)
                return res
            } else {
                return nil
            }
        } catch {
            return nil
        }
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
        let fileManager = FileManager.default
        guard let containerURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
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
}
