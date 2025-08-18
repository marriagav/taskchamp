import SwiftUI
import taskchampShared

struct NoSyncServiceView: View {
    @Binding var isShowingSyncServiceModal: Bool
    @Binding var selectedSyncType: TaskchampionService.SyncType?
    @Environment(PathStore.self) var pathStore: PathStore
    @State private var isShowingAlert = false

    var isDisabled: Bool {
        selectedSyncType == TaskchampionService.SyncType.none
    }

    var buttonTitle: String {
        isDisabled ? "No Sync Enabled" : "Continue Without Sync"
    }

    var body: some View {
        Form {
            Section {
                Text(
                    // swiftlint:disable:next line_length
                    "No Sync means that your tasks will not be synchronized across devices. You will only be able to access them on this device. You can always enable sync later."
                )
                .foregroundStyle(.secondary)
            }
            Section {
                Button(action: {
                    do {
                        try SyncServiceViewHelper.setReplica(syncType: .none)
                        try SyncServiceViewHelper.setUserDefaults(syncType: .none)
                    } catch {
                        isShowingAlert = true
                        return
                    }
                    selectedSyncType = TaskchampionService.SyncType.none
                    isShowingSyncServiceModal = false
                }, label: {
                    Label(buttonTitle, systemImage: SFSymbols.cloudSlash.rawValue)
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
                message: Text("Please try again later."),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationTitle("No Sync")
        .navigationBarTitleDisplayMode(.inline)
    }
}
