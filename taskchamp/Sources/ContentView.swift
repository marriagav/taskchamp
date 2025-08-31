import SwiftUI
import taskchampShared

public struct ContentView: View {
    @State private var pathStore = PathStore()
    @State private var isShowingAlert = false
    @State private var selectedFilter: TCFilter = .defaultFilter
    @State private var selectedSyncType: TaskchampionService.SyncType?
    @State private var isShowingSyncServiceModal = false
    @State private var isLoading = true

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
        try await TaskchampionService.shared.sync()
    }

    public var body: some View {
        NavigationStack(path: $pathStore.path) {
            if isLoading {
                VStack {}
            } else {
                TaskListView(
                    isShowingICloudAlert: $isShowingAlert,
                    selectedFilter: $selectedFilter,
                    selectedSyncType: $selectedSyncType
                )
            }
        }
        .task {
            isLoading = true
            selectedSyncType = getSelectedSyncType()
            guard let selectedSyncType = selectedSyncType else {
                isShowingSyncServiceModal = true
                isLoading = false
                return
            }
            selectedFilter = getSelectedFilter()
            let syncService = TaskchampionService.shared.getSyncServiceFromType(selectedSyncType)
            if !syncService.isAvailable() {
                isShowingAlert = true
            }
            do {
                try await setReplicaAndSync()
                isLoading = false
            } catch {
                isShowingAlert = true
                isLoading = false
            }
        }
        .fullScreenCover(isPresented: $isShowingSyncServiceModal) {
            SyncServiceView(
                isShowingSyncServiceModal: $isShowingSyncServiceModal,
                selectedSyncType: $selectedSyncType
            )
        }
        .environment(pathStore)
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text(TaskchampionService.shared.getSyncServiceFromType(selectedSyncType ?? .none).errorTitle),
                message: Text(
                    TaskchampionService.shared.getSyncServiceFromType(selectedSyncType ?? .none).errorMessage
                ),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
