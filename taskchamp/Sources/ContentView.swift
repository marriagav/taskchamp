import SwiftUI
import taskchampShared

@Observable
class GlobalState {
    var isSyncingTasks = true
    var isShowingPaywall = false
    var lastRemindersImportCount: Int = 0
}

public struct ContentView: View {
    @State private var pathStore = PathStore()
    @State private var globalState = GlobalState()
    @State private var storeKit = StoreKitManager()

    @State private var isShowingAlert = false
    @State private var selectedFilter: TCFilter = .defaultFilter
    @State private var selectedSyncType: TaskchampionService.SyncType?
    @State private var isShowingSyncServiceModal = false
    @State var isShowingCreateTaskView = false
    @Environment(\.scenePhase) private var scenePhase

    public init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.tintColor]
    }

    private func getSelectedFilter() -> TCFilter {
        let value: TCFilter? = UserDefaultsManager.standard.getDecodedValue(forKey: .selectedFilter)
        if let value = value {
            return value
        }
        return .defaultFilter
    }

    private func getSelectedSyncType() -> TaskchampionService.SyncType? {
        return FileService.shared.getSelectedSyncType()
    }

    func setReplicaAndSync() async throws {
        let localReplicaPath = try FileService.shared.getDestinationPathForLocalReplica()
        try TaskchampionService.shared.setDbUrl(path: localReplicaPath)
        try await TaskchampionService.shared.sync {
            globalState.isSyncingTasks = false
        }
    }

    /// Imports reminders from Apple Reminders if capture is enabled
    func importRemindersIfEnabled() async {
        let service = RemindersCaptureService.shared
        guard service.isConfigured else {
            return
        }
        do {
            let result = try await service.importReminders()
            globalState.lastRemindersImportCount = result.importedCount
        } catch {
            print("Failed to import reminders: \(error)")
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
                let task = try TaskchampionService.shared.getTask(uuid: uuidString)
                pathStore.path.append(task)
            } catch {
                print(error)
            }
        }
    }

    public var body: some View {
        NavigationStack(path: $pathStore.path) {
            TaskListView(
                isShowingICloudAlert: $isShowingAlert,
                selectedFilter: $selectedFilter,
                selectedSyncType: $selectedSyncType,
                isShowingCreateTaskView: $isShowingCreateTaskView
            )
        }
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
        .task {
            globalState.isSyncingTasks = true
            try? await storeKit.onAppInitialization()
            selectedSyncType = getSelectedSyncType()
            guard let selectedSyncType = selectedSyncType else {
                isShowingSyncServiceModal = true
                globalState.isSyncingTasks = false
                return
            }
            selectedFilter = getSelectedFilter()
            let syncService = TaskchampionService.shared.getSyncServiceFromType(selectedSyncType)
            if !syncService.isAvailable() {
                isShowingAlert = true
            }
            do {
                try await setReplicaAndSync()
                // Import reminders after initial sync
                await importRemindersIfEnabled()
            } catch {
                isShowingAlert = true
                globalState.isSyncingTasks = false
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Import reminders when app becomes active
                Task {
                    await importRemindersIfEnabled()
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingSyncServiceModal) {
            SyncServiceView(
                isShowingSyncServiceModal: $isShowingSyncServiceModal,
                selectedSyncType: $selectedSyncType
            )
        }
        .environment(pathStore)
        .environment(globalState)
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text(TaskchampionService.shared.getSyncServiceFromType(selectedSyncType ?? .none).errorTitle),
                message: Text(
                    TaskchampionService.shared.getSyncServiceFromType(selectedSyncType ?? .none).errorMessage
                ),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $globalState.isShowingPaywall) {
            TCPaywall()
                .environment(storeKit)
        }
        .environment(storeKit)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
