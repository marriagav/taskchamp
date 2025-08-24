import SwiftUI
import taskchampShared

public struct ContentView: View {
    @State private var pathStore = PathStore()
    @State private var isShowingAlert = false
    @State private var selectedFilter: TCFilter = .defaultFilter
    @State private var selectedSyncType: TaskchampionService.SyncType?
    @State private var isShowingSyncServiceModal = false

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

    public var tasklistView: TaskListView {
        TaskListView(
            isShowingICloudAlert: $isShowingAlert,
            selectedFilter: $selectedFilter,
            selectedSyncType: $selectedSyncType
        )
    }

    public var body: some View {
        NavigationStack(path: $pathStore.path) {
            tasklistView
        }
        .onAppear {
            selectedSyncType = getSelectedSyncType()
            guard let selectedSyncType = selectedSyncType else {
                isShowingSyncServiceModal = true
                return
            }
            selectedFilter = getSelectedFilter()
            let syncService = TaskchampionService.shared.getSyncServiceFromType(selectedSyncType)
            if !syncService.isAvailable() {
                isShowingAlert = true
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
