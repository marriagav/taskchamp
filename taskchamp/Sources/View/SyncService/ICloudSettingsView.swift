import SwiftUI
import taskchampShared

@Observable
class ICloudSettingsViewModel: UseSyncServiceViewModel {
    var isShowingAlert = false

    var syncType: TaskchampionService.SyncType {
        .local
    }

    func isDisabled(for syncType: TaskchampionService.SyncType?) -> Bool {
        syncType == self.syncType
    }

    func buttonTitle(for selectedSyncType: TaskchampionService.SyncType?) -> String {
        isDisabled(for: selectedSyncType) ? "iCloud Sync Enabled" : "Enable iCloud Sync"
    }

    let summary: String =
        // swiftlint:disable:next line_length
        "iCloud Sync works by creating a local `taskchampion-local-sync-server.sqlite3` file that will be used by all of your clients"

    let instructions: [String] = [
        "1. Make sure that iCloud drive is enabled for Taskchamp.",
        "2. If you previously used taskchamp, the db file will automatically be copied to the new location",
        // swiftlint:disable:next line_length
        "3. Otherwise, you need to manually copy your `taskchampion.sqlite3` file into the following directory: `~/Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/taskchamp/`",
        "4. **NOTE: you do not need to move the file, only a copy is needed**",
        "5. Open the taskwarrior configuration file, usually located at `~/.taskrc`, and add the following line:",
        "`sync.local.server_dir=~/Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/taskchamp`",
        "6. You will be able to trigger the sync from your computer by executing: `task sync`",
        "7. Press the button below to finalize"
    ]

    func completeAction(
        isShowingSyncServiceModal: Binding<Bool>,
        selectedSyncType: Binding<TaskchampionService.SyncType?>,
        isShowingAlert: Binding<Bool>
    ) {
        if isDisabled(for: selectedSyncType.wrappedValue) {
            return
        }
        if !ICloudSyncService.isAvailable() {
            isShowingAlert.wrappedValue = true
            return
        }
        do {
            try FileService.shared.copyLegacyDbToICloud()
        } catch {
            isShowingAlert.wrappedValue = true
            return
        }
        do {
            try setReplica()
            try TaskchampionService.shared.sync(syncType: syncType)
            let needsSync = TaskchampionService.shared.needToSync
            if needsSync {
                isShowingAlert.wrappedValue = true
                return
            }
        } catch {
            isShowingAlert.wrappedValue = true
            return
        }
        do {
            try setUserDefaults()
        } catch {
            isShowingAlert.wrappedValue = true
            return
        }
        selectedSyncType.wrappedValue = syncType
        isShowingSyncServiceModal.wrappedValue = false
    }
}

struct ICloudSettingsView: View {
    @Binding var isShowingSyncServiceModal: Bool
    @Binding var selectedSyncType: TaskchampionService.SyncType?
    @Environment(PathStore.self) var pathStore: PathStore

    @State private var viewModel = ICloudSettingsViewModel()

    func completeAction() {
        viewModel.completeAction(
            isShowingSyncServiceModal: $isShowingSyncServiceModal,
            selectedSyncType: $selectedSyncType,
            isShowingAlert: $viewModel.isShowingAlert
        )
    }

    var body: some View {
        return TCInstructionsView(
            summary: viewModel.summary,
            instructions: viewModel.instructions,
        ) {
            TCSyncServiceButtonSectionView(
                buttonTitle: viewModel.buttonTitle(for: selectedSyncType),
                action: completeAction,
                isDisabled: viewModel.isDisabled(for: selectedSyncType),
            )
        }
        .alert(isPresented: $viewModel.isShowingAlert) {
            Alert(
                title: Text("There was an error"),
                message: Text("Make sure that you have an iCloud account and iCloud Drive enabled"),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
    }
}
