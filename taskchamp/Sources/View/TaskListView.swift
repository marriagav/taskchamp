import SwiftData
import SwiftUI
import taskchampShared
import UIKit

public struct TaskListView: View {
    @Environment(PathStore.self) var pathStore: PathStore
    @Environment(\.scenePhase) var scenePhase

    @Binding var isShowingICloudAlert: Bool
    @Binding var selectedFilter: TCFilter

    @State var taskChampionFileUrlString: String?
    @State var tasks: [TCTask] = []
    @State var isShowingCreateTaskView = false
    @State var selection = Set<String>()
    @State var editMode: EditMode = .inactive
    @State var searchText = ""
    @State var isShowingFilterView = false
    @State var sortType: TasksHelper.TCSortType = .init(
        rawValue: UserDefaults.standard
            .string(forKey: "sortType") ?? TasksHelper.TCSortType.defaultSort.rawValue
    ) ?? .defaultSort

    private var searchedTasks: [TCTask] {
        if searchText.isEmpty {
            return tasks
        }
        return tasks.filter { $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.project?.localizedCaseInsensitiveContains(searchText) ?? false ||
            $0.priority?.rawValue.localizedCaseInsensitiveContains(searchText) ?? false ||
            $0.localDate.localizedCaseInsensitiveContains(searchText)
            || $0.status.rawValue.localizedCaseInsensitiveContains(searchText)
            || $0.project?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    private var isEditModeActive: Bool {
        return editMode.isEditing == true
    }

    public init(isShowingICloudAlert: Binding<Bool>, selectedFilter: Binding<TCFilter>) {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.tintColor]
        _isShowingICloudAlert = isShowingICloudAlert
        _selectedFilter = selectedFilter
    }

    private func sortButton(sortType: TasksHelper.TCSortType) -> some View {
        let label = sortType == .defaultSort ? "Default" : sortType == .date ? "Date" : "Priority"
        if self.sortType != sortType {
            return AnyView(
                Button(label) {
                    self.sortType = sortType
                    UserDefaults.standard.set(sortType.rawValue, forKey: "sortType")
                    updateTasks()
                }
            )
        }
        return AnyView(
            Button {
                self.sortType = sortType
                UserDefaults.standard.set(sortType.rawValue, forKey: "sortType")
                updateTasks()
            } label: {
                Label(label, systemImage: SFSymbols.checkmark.rawValue)
            }
        )
    }

    public var body: some View {
        List(selection: $selection) {
            ForEach(searchedTasks, id: \.uuid) { task in
                NavigationLink(value: task) {
                    TaskCellView(task: task)
                }
                .if(task.status != .deleted) {
                    $0.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            updateTasks([task.uuid], withStatus: task.isCompleted ? .pending : .completed)
                        } label: {
                            Label(
                                task.isCompleted ? "Undone" : "Done",
                                systemImage: task.isCompleted ? SFSymbols.backArrow.rawValue : SFSymbols.checkmark
                                    .rawValue
                            )
                        }
                        .tint(task.isCompleted ? .yellow : .green)
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button(role: task.isDeleted ? .cancel : .destructive) {
                        updateTasks([task.uuid], withStatus: task.isDeleted ? .pending : .deleted)
                    } label: {
                        Label(
                            task.isDeleted ? "Restore" : "Delete",
                            systemImage: task.isDeleted ? SFSymbols.backArrow.rawValue : SFSymbols.trash.rawValue
                        )
                    }
                }
                .listRowBackground(Color.clear)
            }
        }
        .searchable(text: $searchText)
        .animation(.default, value: sortType)
        .animation(.default, value: searchText)
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
                    Divider()
                    Menu("Sort by") {
                        sortButton(sortType: .defaultSort)
                        sortButton(sortType: .date)
                        sortButton(sortType: .priority)
                    }
                    Button("Filters") {
                        isShowingFilterView.toggle()
                    }
                    Button("Clear filters") {
                        withAnimation {
                            selectedFilter = .defaultFilter
                            do {
                                let res = try JSONEncoder().encode(selectedFilter)
                                UserDefaults.standard.set(res, forKey: "selectedFilter")
                            } catch { print(error) }
                        }
                    }
                    .disabled(selectedFilter.fullDescription == TCFilter.defaultFilter.fullDescription)
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
        .onChange(of: selectedFilter) {
            updateTasks()
        }
        .sheet(isPresented: $isShowingCreateTaskView, onDismiss: {
            updateTasks()
        }, content: {
            CreateTaskView()
        })
        .sheet(isPresented: $isShowingFilterView) {
            AddFilterView(selectedFilter: $selectedFilter)
        }
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
                selectedFilter.fullDescription
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
