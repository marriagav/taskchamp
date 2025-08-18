import SwiftUI
import taskchampShared

struct ICloudSettingsView: View {
    @Binding var isShowingSyncServiceModal: Bool
    @Binding var selectedSyncType: TaskchampionService.SyncType?
    @Environment(PathStore.self) var pathStore: PathStore
    @State private var isShowingAlert = false

    var isDisabled: Bool {
        selectedSyncType == .local
    }

    var buttonTitle: String {
        isDisabled ? "iCloud Sync Enabled" : "Enable iCloud Sync"
    }

    var body: some View {
        Form {
            Section {
                Text(
                    // swiftlint:disable:next line_length
                    "iCloud Sync works by creating a local `taskchampion-local-sync-server.sqlite3` file that will be used by all of your clients"
                )
                .foregroundStyle(.secondary)
            }
            Section {
                Text(
                    "1. Make sure that iCloud drive is enabled for Taskchamp."
                )
                Text(
                    "2. If you previously used taskchamp, the db file will automatically be copied to the new location"
                )
                Text(
                    // swiftlint:disable:next line_length
                    "3. Otherwise, you need to manually copy your `taskchampion.sqlite3` file into the following directory: `~/Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/taskchamp/`"
                )
                Text(
                    "4. **NOTE: you do not need to move the file, only a copy is needed**"
                )
                Text(
                    // swiftlint:disable:next line_length
                    "5. Open the taskwarrior configuration file, usually located at `~/.taskrc`, and add the following line:"
                )
                Text(
                    "`sync.local.server_dir=~/Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/taskchamp`"
                )
                Text(
                    "6. You will be able to trigger the sync from your computer by executing: `task sync`"
                )
                Text(
                    "7. Press the button below to finalize"
                )
            }
            Section {
                Button(action: {
                    if !ICloudSyncService.isAvailable() {
                        isShowingAlert = true
                        return
                    }
                    do {
                        try FileService.shared.copyLegacyDbToICloud()
                    } catch {
                        isShowingAlert = true
                        return
                    }
                    do {
                        try SyncServiceViewHelper.setReplica(syncType: .local)
                        try TaskchampionService.shared.sync(syncType: .local)
                        let needsSync = TaskchampionService.shared.needToSync
                        if needsSync {
                            isShowingAlert = true
                            return
                        }
                    } catch {
                        isShowingAlert = true
                        return
                    }
                    do {
                        try SyncServiceViewHelper.setUserDefaults(syncType: .local)
                    } catch {
                        isShowingAlert = true
                        return
                    }
                    selectedSyncType = .local
                    isShowingSyncServiceModal = false
                }, label: {
                    Label(buttonTitle, systemImage: SFSymbols.cloud.rawValue)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                })
                .buttonStyle(.borderedProminent)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .disabled(isDisabled)
            }
        }
        .alert(isPresented: $isShowingAlert) {
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
