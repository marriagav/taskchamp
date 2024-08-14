import SwiftUI

public struct ContentView: View {
    @State private var taskChampionFileUrlString: String?
    @State private var tasks: [Task] = []
    public init() {}

    func completeTask(_ uuid: String) {
        do {
            // guard let path = taskChampionFileUrlString else {
            //     throw TCError.genericError("No access or path")
            // }
            // DBService.shared.setDbUrl(path)
            try DBService.shared.completeTask(uuid)
            updateTasks()
        } catch {
            print(error)
        }
    }

    func updateTasks(setDb: Bool = false) {
        do {
            if setDb {
                guard let path = taskChampionFileUrlString else {
                    throw TCError.genericError("No access or path")
                }

                DBService.shared.setDbUrl(path)
            }
            tasks = try DBService.shared.getPendingTasks()
        } catch {
            print(error)
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

    func copyDatabaseIfNeeded() {
        let sourcePath = Bundle.main.path(forResource: "taskchampion", ofType: "sqlite3")
        guard let sourcePath = sourcePath else {
            return
        }
        let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
        guard let containerURL = containerURL else {
            return
        }

        let documentsURL = containerURL.appendingPathComponent("Documents")
        let taskDirectory = documentsURL.appendingPathComponent("task")
        let destinationPath = taskDirectory.appendingPathComponent("taskchampion.sqlite3")

        createDirectoryIfNeeded(url: documentsURL)
        createDirectoryIfNeeded(url: taskDirectory)

        let exists = FileManager.default.fileExists(atPath: destinationPath.path)
        guard !exists else {
            taskChampionFileUrlString = destinationPath.path
            updateTasks(setDb: true)
            return
        }
        do {
            try FileManager.default.copyItem(atPath: sourcePath, toPath: destinationPath.path)
            taskChampionFileUrlString = destinationPath.path
            updateTasks(setDb: true)
            return
        } catch {
            print("error during file copy: \(error)")
            return
        }
    }

    public var body: some View {
        NavigationStack {
            List {
                ForEach(tasks, id: \.uuid) { task in
                    TaskCellView(task: task)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                completeTask(task.uuid)
                            } label: {
                                Label("Done", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                }
            }
            .refreshable {
                updateTasks()
            }
            .listStyle(.insetGrouped)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        Label("Select taskchampion task folder", systemImage: "doc.text.fill")
                    }
                }
            }
            .onAppear {
                copyDatabaseIfNeeded()
            }
            .navigationTitle("My Tasks")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
