import SwiftUI

public struct ContentView: View {
    @State private var isPickerShowing = false
    @State private var taskChampionFileUrl: URL?
    @State private var tasks: [Task] = []
    public init() {}

    func completeTask(_ task: Task) {
        do {
            let access = taskChampionFileUrl?.startAccessingSecurityScopedResource()
            print("Access to the file : \(access)")
            try DBService.shared.completeTask(task)
            updateTasks()
            taskChampionFileUrl?.stopAccessingSecurityScopedResource()
        } catch {
            print(error)
        }
    }

    func updateTasksTest() {
        do {
            let access = taskChampionFileUrl?.startAccessingSecurityScopedResource()
            guard let access, let path = taskChampionFileUrl?.path else {
                throw TCError.genericError("No access or path")
            }
            DBService.shared.setDbUrl(path)
            tasks = try DBService.shared.getPendingTasks()
            print("Access to the file : \(access)")
            taskChampionFileUrl?.stopAccessingSecurityScopedResource()
        } catch {
            print(error)
        }
    }

    func updateTasks() {
        do {
            let access = taskChampionFileUrl?.startAccessingSecurityScopedResource()
            tasks = try DBService.shared.getPendingTasks()
            print("Access to the file : \(access)")
            taskChampionFileUrl?.stopAccessingSecurityScopedResource()
        } catch {
            print(error)
        }
    }

    public var body: some View {
        NavigationStack {
            List {
                ForEach(tasks, id: \.uuid) { task in
                    TaskCellView(task: task)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                completeTask(task)
                            } label: {
                                Label("Done", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                }
            }
            .refreshable {
                updateTasksTest()
            }
            .listStyle(.insetGrouped)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPickerShowing.toggle()
                    } label: {
                        Label("Select taskchampion task folder", systemImage: "doc.text.fill")
                    }
                }
            }
            .fileImporter(
                isPresented: $isPickerShowing,
                allowedContentTypes: [.data]
            ) { result in
                switch result {
                case let .success(url):
                    let gotAccess = url.startAccessingSecurityScopedResource()
                    print("Access to the file : \(gotAccess)")

                    DBService.shared.setDbUrl(url.path)

                    updateTasks()

                    url.stopAccessingSecurityScopedResource()
                    taskChampionFileUrl = url

                case let .failure(error):
                    print(error)
                }
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
