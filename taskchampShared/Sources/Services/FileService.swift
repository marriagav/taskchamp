import Foundation

// swiftlint:disable:next type_body_length
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

    func createFileIfNeeded(url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
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

        guard url.startAccessingSecurityScopedResource() else {
            throw TCError.genericError("Failed to access security scoped resource")
        }

        let data = createSecurityScopedBookmark(for: url)
        guard let data else {
            url.stopAccessingSecurityScopedResource()
            throw TCError.genericError("Failed to create bookmark")
        }

        UserDefaultsManager.shared.set(value: data, forKey: .taskNoteFolderBookmark)
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
        url.stopAccessingSecurityScopedResource()
    }

    func createSecurityScopedBookmark(for url: URL) -> Data? {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            return bookmarkData
        } catch {
            return nil
        }
    }

    public func createObsidianNote(
        for taskNote: String,
        taskStatus: TCTask.Status = .pending
    ) throws -> URL {
        let bookmarkData: Data? = UserDefaultsManager.shared.getValue(forKey: .taskNoteFolderBookmark)
        guard let bookmarkData else {
            throw TCError.genericError("No bookmark data")
        }

        var isStale = false

        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        guard url.startAccessingSecurityScopedResource() else {
            throw TCError.genericError("Failed to access security scoped resource")
        }

        let noteURL = url.appendingPathComponent(taskNote + ".md")
        let exists = FileManager.default.fileExists(atPath: noteURL.path)
        if exists {
            url.stopAccessingSecurityScopedResource()
            return noteURL
        }

        if taskStatus == .completed {
            let doneNoteURL = url.appendingPathComponent("done/" + taskNote + ".md")
            let exists = FileManager.default.fileExists(atPath: doneNoteURL.path)
            if exists {
                url.stopAccessingSecurityScopedResource()
                return doneNoteURL
            }
        }

        createFileIfNeeded(url: noteURL)
        url.stopAccessingSecurityScopedResource()

        return noteURL
    }

    public func getContentsOfObsidianNote(for taskNote: String) throws -> (String?, URL)? {
        let bookmarkData: Data? = UserDefaultsManager.shared.getValue(forKey: .taskNoteFolderBookmark)
        guard let bookmarkData else {
            throw TCError.genericError("No bookmark data")
        }

        var isStale = false

        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        guard url.startAccessingSecurityScopedResource() else {
            throw TCError.genericError("Failed to access security scoped resource")
        }

        let noteURL = url.appendingPathComponent(taskNote + ".md")
        let exists = FileManager.default.fileExists(atPath: noteURL.path)
        if exists {
            let fileContents = getFileContents(url: noteURL)
            url.stopAccessingSecurityScopedResource()
            return (fileContents, noteURL)
        }

        let doneNoteURL = url.appendingPathComponent("done/" + taskNote + ".md")
        let doneExists = FileManager.default.fileExists(atPath: doneNoteURL.path)
        if doneExists {
            let fileContents = getFileContents(url: doneNoteURL)
            url.stopAccessingSecurityScopedResource()
            return (fileContents, doneNoteURL)
        }

        url.stopAccessingSecurityScopedResource()
        return nil
    }

    public func saveContentsToObsidianNote(for taskNote: String, content: String) throws {
        let bookmarkData: Data? = UserDefaultsManager.shared.getValue(forKey: .taskNoteFolderBookmark)
        guard let bookmarkData else {
            throw TCError.genericError("No bookmark data")
        }

        var isStale = false

        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        guard url.startAccessingSecurityScopedResource() else {
            throw TCError.genericError("Failed to access security scoped resource")
        }

        let noteURL = url.appendingPathComponent(taskNote + ".md")
        let exists = FileManager.default.fileExists(atPath: noteURL.path)
        if !exists {
            createFileIfNeeded(url: noteURL)
        }

        do {
            try content.write(to: noteURL, atomically: true, encoding: .utf8)
        } catch {
            url.stopAccessingSecurityScopedResource()
            throw TCError.genericError("Failed to write to file: \(error.localizedDescription)")
        }

        url.stopAccessingSecurityScopedResource()
    }

    public func obsidianNoteAfter(component: String, url: URL) -> String? {
        let components = url.pathComponents

        if let index = components.firstIndex(of: component) {
            let remaining = components.suffix(from: index + 1)
            return remaining.joined(separator: "/").replacingOccurrences(of: ".md", with: "")
        }
        return nil
    }

    public func getFileContents(url: URL) -> String? {
        let contents = try? String(contentsOf: url, encoding: .utf8)
        return contents
    }
}
