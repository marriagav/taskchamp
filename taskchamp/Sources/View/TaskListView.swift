import SwiftUI
import UIKit

public struct TaskListView: View {
    @State private var taskChampionFileUrlString: String?
    @State private var tasks: [Task] = []
    @State private var isShowingCreateTaskView: Bool = false
    @State private var selection = Set<String>()

    @State private var editMode: EditMode = .inactive

    private var isEditModeActive: Bool {
        return editMode.isEditing == true
    }

    public init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.tintColor]
    }

    func setDbUrl() throws {
        guard let path = taskChampionFileUrlString else {
            throw TCError.genericError("No access or path")
        }
        DBService.shared.setDbUrl(path)
    }

    func updateTasks(_ uuids: Set<String>, withStatus newStatus: Task.Status) {
        do {
            try setDbUrl()
            try DBService.shared.updatePendingTasks(uuids, withStatus: newStatus)
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
        List(selection: $selection) {
            ForEach(tasks, id: \.uuid) { task in
                TaskCellView(task: task)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            updateTasks([task.uuid], withStatus: .completed)
                        } label: {
                            Label("Done", systemImage: SFSymbols.checkmark.rawValue)
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            updateTasks([task.uuid], withStatus: .deleted)
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
                if isEditModeActive {
                    HStack {
                        Button("Complete") {
                            updateTasks(selection, withStatus: .completed)
                        }
                        .disabled(selection.isEmpty)
                        Spacer()
                        Button {
                            updateTasks(selection, withStatus: .deleted)
                        } label: {
                            Label(
                                "Delete",
                                systemImage: SFSymbols.trash.rawValue
                            )
                        }
                        .disabled(selection.isEmpty)
                    }
                    .animation(.default, value: editMode)
                } else {
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
                    .animation(.default, value: editMode)
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
            ToolbarItemGroup(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $isShowingCreateTaskView, onDismiss: {
            updateTasks()
        }, content: {
            CreateTaskView()
        })
        .navigationTitle(
            isEditModeActive ? selection.isEmpty ? "Select Tasks" : "\(selection.count) Selected" :
                "My Tasks"
        )
        .environment(\.editMode, $editMode)
    }
}

struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
    }
}
