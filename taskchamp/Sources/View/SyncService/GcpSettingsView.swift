import SwiftUI
import taskchampShared

@Observable
class GcpSettingsViewModel: UseSyncServiceViewModel {
    var isShowingAlert = false
    var isImporting = false
    var gcpBucket: String = ""
    var gcpServerCredentialPath: String = ""
    var gcpServerEncryptionSecret: String = ""

    var syncType: TaskchampionService.SyncType {
        .gcp
    }

    var summary: String {
        // swiftlint:disable:next line_length
        "GCP Sync works by connecting to a GCP bucket that will handle the synchronization of your tasks across devices."
    }

    func buttonTitle(for _: TaskchampionService.SyncType? = nil) -> String {
        return "Save Gcp Sync"
    }

    func setOtherUserDefaults() {
        do {
            let encodedBucket = try JSONEncoder().encode(gcpBucket)
            let encodedCredentialPath = try JSONEncoder().encode(gcpServerCredentialPath)
            let encodedEncryptionSecret = try JSONEncoder().encode(gcpServerEncryptionSecret)
            let defaults = UserDefaults(suiteName: "group.com.mav.taskchamp")
            guard let defaults else {
                isShowingAlert = true
                return
            }
            defaults.set(encodedBucket, forKey: "gcpServerBucket")
            defaults.set(encodedCredentialPath, forKey: "gcpServerCredentialPath")
            defaults.set(encodedEncryptionSecret, forKey: "gcpServerEncryptionSecret")
        } catch {
            isShowingAlert = true
        }
    }

    func onAppear() {
        if let bucket = GcpSyncService.getGcpBucket() {
            gcpBucket = bucket
        }

        if let credentialPath = GcpSyncService.getGcpCredentialPath() {
            gcpServerCredentialPath = credentialPath
        }
        if let encryptionSecret = GcpSyncService.getGcpEncryptionSecret() {
            gcpServerEncryptionSecret = encryptionSecret
        }
    }

    func onFileImportWithResult(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            if let url = urls.first {
                gcpServerCredentialPath = url.path
            }
        case .failure:
            isShowingAlert = true
        }
    }
}

struct GcpSettingsView: View {
    @Binding var isShowingSyncServiceModal: Bool
    @Binding var selectedSyncType: TaskchampionService.SyncType?
    @Environment(PathStore.self) var pathStore: PathStore

    @State private var viewModel = GcpSettingsViewModel()

    func completeAction() {
        viewModel.completeAction(
            isShowingSyncServiceModal: $isShowingSyncServiceModal,
            selectedSyncType: $selectedSyncType,
            isShowingAlert: $viewModel.isShowingAlert
        )
    }

    var body: some View {
        TCInstructionsView(
            summary: viewModel.summary,
            instructions: viewModel.instructions
        ) {
            Section {
                Text(
                    "**Bucket in which to store the task data. This bucket must not be used for any other purpose.**"
                )
                TextField("GCP Server bucket", text: $viewModel.gcpBucket)
                    .autocapitalization(.none)
                Text(
                    "**Path to a GCP credential file, in JSON format.**"
                )
                Button(action: {
                    viewModel.isImporting = true
                }, label: {
                    Label(
                        viewModel.gcpServerCredentialPath.isEmpty ? "Import GCP Credential File" : FileService.shared
                            .getFIleNameFromPath(path: viewModel.gcpServerCredentialPath),
                        systemImage: SFSymbols.folder.rawValue
                    )
                })
                Text(
                    // swiftlint:disable:next line_length
                    "**Private encryption secret used to encrypt all data sent to the server. This can be any suitably un-guessable string of bytes.**"
                )
                SecureField("Remote Encryption Secret", text: $viewModel.gcpServerEncryptionSecret)
                    .autocapitalization(.none)
            }
            TCSyncServiceButtonSectionView(buttonTitle: viewModel.buttonTitle(), action: completeAction)
        }
        .alert(isPresented: $viewModel.isShowingAlert) {
            Alert(
                title: Text("There was an error"),
                message: Text("Make sure that you set the GCP server configurations"),
                dismissButton: .default(Text("OK"))
            )
        }
        .fileImporter(
            isPresented: $viewModel.isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            viewModel.onFileImportWithResult(result)
        }
        .navigationTitle("Google Cloud Platform Sync")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
    }
}
