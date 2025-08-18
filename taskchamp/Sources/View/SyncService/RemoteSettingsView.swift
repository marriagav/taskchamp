import SwiftUI
import taskchampShared

struct RemoteSettingsView: View {
    @Binding var isShowingSyncServiceModal: Bool
    @Binding var selectedSyncType: TaskchampionService.SyncType?
    @Environment(PathStore.self) var pathStore: PathStore
    @State private var isShowingAlert = false

    @State private var remoteServerUrl: String = ""
    @State private var remoteClientId: String = ""
    @State private var remoteEncryptionSecret: String = ""

    private func setOtherUserDefaults() {
        do {
            let encodedUrl = try JSONEncoder().encode(remoteServerUrl)
            let encodedClientId = try JSONEncoder().encode(remoteClientId)
            let encodedEncryptionSecret = try JSONEncoder().encode(remoteEncryptionSecret)
            let defaults = UserDefaults(suiteName: "group.com.mav.taskchamp")
            guard let defaults else {
                isShowingAlert = true
                return
            }
            defaults.set(encodedUrl, forKey: "remoteServerUrl")
            defaults.set(encodedClientId, forKey: "remoteServerClientId")
            defaults.set(encodedEncryptionSecret, forKey: "remoteServerEncryptionSecret")
        } catch {
            isShowingAlert = true
        }
    }

    var buttonTitle: String {
        "Save Remote Sync"
    }

    var body: some View {
        Form {
            Section {
                Text(
                    // swiftlint:disable:next line_length
                    "Remote Sync works by connecting to a remote taskchampion-sync-server that will handle the synchronization of your tasks across devices."
                )
                .foregroundStyle(.secondary)
            }
            Section {
                Text(
                    "**The base URL of the Sync server**"
                )
                TextField("Remote Server URL", text: $remoteServerUrl)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                Text(
                    "**Client ID to identify and authenticate this replica to the server**"
                )
                TextField("Remote Client ID", text: $remoteClientId)
                    .autocapitalization(.none)
                Text(
                    // swiftlint:disable:next line_length
                    "**Private encryption secret used to encrypt all data sent to the server. This can be any suitably un-guessable string of bytes.**"
                )
                SecureField("Remote Encryption Secret", text: $remoteEncryptionSecret)
                    .autocapitalization(.none)
            }
            Section {
                Button(action: {
                    setOtherUserDefaults()
                    do {
                        try SyncServiceViewHelper.setReplica(syncType: .remote)
                        try TaskchampionService.shared.sync(syncType: .remote)
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
                        try SyncServiceViewHelper.setUserDefaults(syncType: .remote)
                    } catch {
                        isShowingAlert = true
                        return
                    }

                    selectedSyncType = .remote
                    isShowingSyncServiceModal = false
                }, label: {
                    Label(buttonTitle, systemImage: SFSymbols.cloud.rawValue)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                })
                .buttonStyle(.borderedProminent)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text("There was an error"),
                message: Text("Make sure that you set the correct server configurations"),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationTitle("taskchampion-sync-server Sync")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
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
}
