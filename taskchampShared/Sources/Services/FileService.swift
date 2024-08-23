import Foundation

public class FileService {
    public static let shared = FileService()

    private init() {}

    public func getDestinationPath() throws -> String {
        let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
        guard let containerURL = containerURL else {
            throw TCError.genericError("No container URL")
        }

        let documentsURL = containerURL.appendingPathComponent("Documents")
        let taskDirectory = documentsURL.appendingPathComponent("task")
        let destinationPath = taskDirectory.appendingPathComponent("taskchampion.sqlite3")

        let exists = FileManager.default.fileExists(atPath: destinationPath.path)
        guard exists else {
            throw TCError.genericError("File not found")
        }
        return destinationPath.path
    }

    public func copyDatabaseIfNeededAndGetDestinationPath() throws -> String {
        let sourcePath = Bundle.main.path(forResource: "taskchampion", ofType: "sqlite3")
        guard let sourcePath = sourcePath else {
            throw TCError.genericError("No source path")
        }
        let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
        guard let containerURL = containerURL else {
            throw TCError.genericError("No container URL")
        }

        let documentsURL = containerURL.appendingPathComponent("Documents")
        let taskDirectory = documentsURL.appendingPathComponent("task")
        let destinationPath = taskDirectory.appendingPathComponent("taskchampion.sqlite3")

        createDirectoryIfNeeded(url: documentsURL)
        createDirectoryIfNeeded(url: taskDirectory)

        let exists = FileManager.default.fileExists(atPath: destinationPath.path)
        guard !exists else {
            return destinationPath.path
        }
        do {
            try FileManager.default.copyItem(atPath: sourcePath, toPath: destinationPath.path)
            return destinationPath.path
        } catch {
            print("error during file copy: \(error)")
            throw error
        }
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
}
