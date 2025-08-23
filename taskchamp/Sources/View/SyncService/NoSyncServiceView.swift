import SwiftUI
import taskchampShared

@Observable
class NoSyncServiceViewModel: UseSyncServiceViewModel {
    var isShowingAlert = false

    var syncType: TaskchampionService.SyncType {
        .none
    }

    func isDisabled(for syncType: TaskchampionService.SyncType?) -> Bool {
        syncType == self.syncType
    }

    func buttonTitle(for selectedSyncType: TaskchampionService.SyncType?) -> String {
        isDisabled(for: selectedSyncType) ? "No Sync Enabled" : "Continue Without Sync"
    }

    var summary: String {
        // swiftlint:disable:next line_length
        "No Sync means that your tasks will not be synchronized across devices. You will only be able to access them on this device. You can always enable sync later."
    }

    func completeAction(
        isShowingSyncServiceModal: Binding<Bool>,
        selectedSyncType: Binding<TaskchampionService.SyncType?>,
        isShowingAlert: Binding<Bool>
    ) {
        do {
            try setReplica()
            try setUserDefaults()
        } catch {
            isShowingAlert.wrappedValue = true
            return
        }
        selectedSyncType.wrappedValue = syncType
        isShowingSyncServiceModal.wrappedValue = false
    }

}

struct NoSyncServiceView: View {
    @Binding var isShowingSyncServiceModal: Bool
    @Binding var selectedSyncType: TaskchampionService.SyncType?
    @Environment(PathStore.self) var pathStore: PathStore

    @State private var viewModel = NoSyncServiceViewModel()

    func completeAction() {
        viewModel.completeAction(
            isShowingSyncServiceModal: $isShowingSyncServiceModal,
            selectedSyncType: $selectedSyncType,
            isShowingAlert: $viewModel.isShowingAlert
        )
    }

    func buttonTitle() -> String {
        viewModel.buttonTitle(for: selectedSyncType)
    }

    var body: some View {
        TCInstructionsView(summary: viewModel.summary, instructions: viewModel.instructions) {
            TCSyncServiceButtonSectionView(
                buttonTitle: viewModel.buttonTitle(for: selectedSyncType),
                action: completeAction,
                isDisabled: viewModel.isDisabled(for: selectedSyncType),
                systemImage: SFSymbols.cloudSlash.rawValue,
            )
        }
        .alert(isPresented: $viewModel.isShowingAlert) {
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
