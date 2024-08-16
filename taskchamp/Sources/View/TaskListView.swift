import SwiftUI
import UIKit

public struct TaskListView: View {
    @State private var taskChampionFileUrlString: String?
    @State private var tasks: [Task] = []
    @State private var isShowingCreateTaskView: Bool = false

    public init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.tintColor]
    }

    func setDbUrl() throws {
        guard let path = taskChampionFileUrlString else {
            throw TCError.genericError("No access or path")
        }
        DBService.shared.setDbUrl(path)
    }

    func updateTask(_ uuid: String, withStatus newStatus: Task.Status) {
        do {
            try setDbUrl()
            try DBService.shared.updatePendingTask(uuid, withStatus: newStatus)
            updateTasks()
        } catch {
            print(error)
        }
    }

    func updateTasks() {
        do {
            try setDbUrl()
            try withAnimation {
                tasks = try DBService.shared.getPendingTasks()
            }
        } catch {
            print(error)
        }
    }

    func copyDatabaseIfNeeded() {
        do {
            taskChampionFileUrlString = try FileService.shared.copyDatabaseIfNeededAndGetDestinationPath()
            updateTasks()
            return
        } catch {
            print(error)
        }
    }

    public var body: some View {
        List {
            ForEach(tasks, id: \.uuid) { task in
                TaskCellView(task: task)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            updateTask(task.uuid, withStatus: .completed)
                        } label: {
                            Label("Done", systemImage: SFSymbols.checkmark.rawValue)
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            updateTask(task.uuid, withStatus: .deleted)
                        } label: {
                            Label("Delete", systemImage: SFSymbols.trash.rawValue)
                        }
                    }
            }
        }
        .refreshable {
            updateTasks()
        }
        .listStyle(.inset)
        .onAppear {
            copyDatabaseIfNeeded()
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack {
                    Button {
                        isShowingCreateTaskView.toggle()
                    } label: {
                        Label(
                            "New Task",
                            systemImage: SFSymbols.plusCircleFill.rawValue
                        )
                        .labelStyle(.titleAndIcon)
                        .imageScale(.large)
                        .bold()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundStyle(.tint)
                    Spacer()
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {} label: {
                    Label(
                        "Options",
                        systemImage: SFSymbols.ellipsisCircle.rawValue
                    )
                    .labelStyle(.titleAndIcon)
                    .imageScale(.large)
                    .bold()
                }
            }
        }
        .sheet(isPresented: $isShowingCreateTaskView) {
            CreateTaskView()
        }
        .navigationTitle("My Tasks")
    }
}

struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
    }
}
