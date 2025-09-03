import SwiftUI
import taskchampShared

@Observable
class RemoteSettingsViewModel: UseSyncServiceViewModel {
    var isShowingAlert = false
    var remoteServerUrl: String = ""
    var remoteClientId: String = ""
    var remoteEncryptionSecret: String = ""

    var syncType: TaskchampionService.SyncType {
        .remote
    }

    var summary: String {
        // swiftlint:disable:next line_length
        "Remote Sync works by connecting to a remote taskchampion-sync-server that will handle the synchronization of your tasks across devices."
    }

    func buttonTitle(for _: TaskchampionService.SyncType? = nil) -> String {
        return "Save Remote Sync"
    }

    func setOtherUserDefaults() {
        UserDefaultsManager.shared.set(value: remoteServerUrl, forKey: .remoteServerUrl)
        UserDefaultsManager.shared.set(value: remoteClientId, forKey: .remoteServerClientId)
        UserDefaultsManager.shared.set(value: remoteEncryptionSecret, forKey: .remoteServerEncryptionSecret)
    }

    func onAppear() {
        if let url = RemoteSyncService.getRemoteServerUrl() {
            remoteServerUrl = url
        }

        if let clientId = RemoteSyncService.getRemoteClientId() {
            remoteClientId = clientId
        }
        if let encryptionSecret = RemoteSyncService.getRemoteEncryptionSecret() {
            remoteEncryptionSecret = encryptionSecret
        }
    }
}

struct RemoteSettingsView: View {
    @Binding var isShowingSyncServiceModal: Bool
    @Binding var selectedSyncType: TaskchampionService.SyncType?
    @Environment(PathStore.self) var pathStore: PathStore

    @State private var viewModel = RemoteSettingsViewModel()
    @State private var isLoading = false

    func completeAction() {
        Task {
            isLoading = true
            await viewModel.completeAction(
                isShowingSyncServiceModal: $isShowingSyncServiceModal,
                selectedSyncType: $selectedSyncType,
                isShowingAlert: $viewModel.isShowingAlert
            )
            isLoading = false
        }
    }

    var body: some View {
        TCInstructionsView(
            summary: viewModel.summary,
            instructions: viewModel.instructions
        ) {
            Section {
                Text(
                    "**The base URL of the Sync server**"
                )
                TextField("Remote Server URL", text: $viewModel.remoteServerUrl)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                Text(
                    "**Client ID to identify and authenticate this replica to the server**"
                )
                TextField("Remote Client ID", text: $viewModel.remoteClientId)
                    .autocapitalization(.none)
                Text(
                    // swiftlint:disable:next line_length
                    "**Private encryption secret used to encrypt all data sent to the server. This can be any suitably un-guessable string of bytes.**"
                )
                SecureField("Remote Encryption Secret", text: $viewModel.remoteEncryptionSecret)
                    .autocapitalization(.none)
            }
            TCSyncServiceButtonSectionView(
                buttonTitle: viewModel.buttonTitle(),
                action: completeAction,
                isDisabled: isLoading
            )
        }
        .alert(isPresented: $viewModel.isShowingAlert) {
            Alert(
                title: Text("There was an error"),
                message: Text("Make sure that you set the correct server configurations"),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationTitle("taskchampion-sync-server Sync")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
    }
}
