import SwiftUI
import taskchampShared
import UIKit

public struct TaskListView: View {
    @Environment(PathStore.self) var pathStore
    @Environment(\.scenePhase) var scenePhase
    @Binding var isShowingICloudAlert: Bool

    @State private var taskChampionFileUrlString: String?
    @State private var tasks: [TCTask] = []
    @State private var isShowingCreateTaskView = false
    @State private var selection = Set<String>()
    @State private var editMode: EditMode = .inactive

    private var isEditModeActive: Bool {
        return editMode.isEditing == true
    }

    public init(isShowingICloudAlert: Binding<Bool>) {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.tintColor]
        _isShowingICloudAlert = isShowingICloudAlert
    }

    func setDbUrl() throws {
        guard let path = taskChampionFileUrlString else {
            throw TCError.genericError("No access or path")
        }
        DBService.shared.setDbUrl(path)
    }

    func updateTasks(_ uuids: Set<String>, withStatus newStatus: TCTask.Status) {
        do {
            try setDbUrl()
            try DBService.shared.updatePendingTasks(uuids, withStatus: newStatus)
            updateTasks()
            NotificationService.shared.removeNotifications(for: Array(uuids))
        } catch {
            print(error)
        }
    }

    func updateTasks() {
        do {
            try setDbUrl()
            let newTasks = try DBService.shared.getPendingTasks()
            if newTasks == tasks {
                return
            }
            try withAnimation {
                tasks = try DBService.shared.getPendingTasks()
            }
        } catch {
            if !FileService.shared.isICloudAvailable() {
                print("iCloud Unavailable")
                isShowingICloudAlert = true
            }
            print(error)
        }
    }

    func copyDatabaseIfNeeded() {
        do {
            if taskChampionFileUrlString != nil {
                updateTasks()
                return
            }
            taskChampionFileUrlString = try FileService.shared.copyDatabaseIfNeededAndGetDestinationPath()
            updateTasks()
            NotificationService.shared.requestAuthorization { success, error in
                if success {
                    print("Notification Authorization granted")
                    Task {
                        await NotificationService.shared.createReminderForTasks(tasks: tasks)
                    }
                } else if let error = error {
                    print(error.localizedDescription)
                }
            }
            return
        } catch {
            print(error)
        }
    }

    func handleDeepLink(url: URL) {
        Task {
            guard url.scheme == "taskchamp", url.host == "task" else {
                return
            }

            let uuidString = url.pathComponents[1]

            if uuidString == "new" {
                isShowingCreateTaskView = true
                return
            }

            do {
                try setDbUrl()
                let task = try DBService.shared.getTask(uuid: uuidString)
                pathStore.path.append(task)
            } catch {
                print(error)
            }
        }
    }

    public var body: some View {
        List(selection: $selection) {
            ForEach(tasks, id: \.uuid) { task in
                NavigationLink(value: task) {
                    TaskCellView(task: task)
                }
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
                .listRowBackground(Color.clear)
            }
        }
        .overlay(
            Group {
                if tasks.isEmpty {
                    ContentUnavailableView {
                        Label("No new tasks", systemImage: "bolt.heart")
                    } description: {
                        Text("Use this time to relax or add new tasks!")
                    } actions: {
                        Button("New task") {
                            isShowingCreateTaskView.toggle()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        )
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
                            selection.removeAll()
                        }
                        .disabled(selection.isEmpty)
                        Spacer()
                        Menu {
                            Button(role: .destructive) {
                                updateTasks(selection, withStatus: .deleted)
                                selection.removeAll()
                            } label: {
                                Label(
                                    "Delete selected tasks",
                                    systemImage: SFSymbols.trash.rawValue
                                )
                            }
                            .disabled(selection.isEmpty)
                        } label: {
                            Label("Delete", systemImage: SFSymbols.trash.rawValue)
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
                Menu {
                    Link(
                        "Documentation",
                        // swiftlint:disable:next force_unwrapping
                        destination: URL(string: "https://github.com/marriagav/taskchamp-docs")!
                    )
                } label: {
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
                if !tasks.isEmpty {
                    EditButton()
                }
            }
        }
        .onChange(of: isEditModeActive) {
            selection.removeAll()
        }
        .sheet(isPresented: $isShowingCreateTaskView, onDismiss: {
            updateTasks()
        }, content: {
            CreateTaskView()
        })
        .navigationDestination(for: TCTask.self) { task in
            EditTaskView(task: task)
                .onDisappear {
                    updateTasks()
                }
                .onAppear {
                    do {
                        try setDbUrl()
                    } catch {
                        print(error)
                    }
                }
        }
        .navigationTitle(
            tasks.isEmpty ? "" : isEditModeActive ? selection.isEmpty ? "Select Tasks" : "\(selection.count) Selected" :
                "My Tasks"
        )
        .environment(\.editMode, $editMode)
        .onOpenURL { url in
            handleDeepLink(url: url)
        }
        .onReceive(NotificationCenter.default.publisher(
            for: .TCTappedDeepLinkNotification
        )) { notification in
            guard let url = notification.object as? URL else {
                return
            }
            handleDeepLink(url: url)
        }
        .onChange(of: scenePhase) { _, newScenePhase in
            if newScenePhase == .active {
                copyDatabaseIfNeeded()
            }
        }
    }
}
