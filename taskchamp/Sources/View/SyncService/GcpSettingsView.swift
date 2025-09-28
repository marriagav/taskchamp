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
        UserDefaultsManager.shared.set(value: gcpBucket, forKey: .gcpServerBucket)
        UserDefaultsManager.shared.set(value: gcpServerCredentialPath, forKey: .gcpServerCredentialPath)
        UserDefaultsManager.shared.set(value: gcpServerEncryptionSecret, forKey: .gcpServerEncryptionSecret)
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
            guard let url = urls.first else {
                return
            }
            guard url.startAccessingSecurityScopedResource() else {
                isShowingAlert = true
                return
            }

            let localPath = try? FileService.shared.copyItemToBundle(atPath: url.path)

            guard let localPath else {
                url.stopAccessingSecurityScopedResource()
                return
            }

            gcpServerCredentialPath = localPath
            url.stopAccessingSecurityScopedResource()
        case .failure:
            isShowingAlert = true
        }
    }
}

struct GcpSettingsView: View, UseKeyboardToolbar {
    @Binding var isShowingSyncServiceModal: Bool
    @Binding var selectedSyncType: TaskchampionService.SyncType?
    @Environment(PathStore.self) var pathStore: PathStore

    @State private var viewModel = GcpSettingsViewModel()
    @State private var isLoading = false

    @FocusState var focusedField: FormField?
    enum FormField {
        case bucket
        case encryptionSecret
    }

    func calculateNextField() {
        switch focusedField {
        case .bucket:
            focusedField = .encryptionSecret
        case .encryptionSecret:
            focusedField = .encryptionSecret
        default:
            focusedField = nil
        }
    }

    func calculatePreviousField() {
        switch focusedField {
        case .bucket:
            focusedField = .bucket
        case .encryptionSecret:
            focusedField = .bucket
        default:
            focusedField = nil
        }
    }

    func onDismissKeyboard() {
        focusedField = nil
    }

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
                    "**Bucket in which to store the task data. This bucket must not be used for any other purpose.**"
                )
                TextField("GCP Server bucket", text: $viewModel.gcpBucket)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .bucket)
                Text(
                    "**Path to a GCP credential file, in JSON format.**"
                )
                Button(action: {
                    viewModel.isImporting = true
                }, label: {
                    Label(
                        viewModel.gcpServerCredentialPath.isEmpty ? "Import GCP Credential File" : FileService.shared
                            .getFileNameFromPath(path: viewModel.gcpServerCredentialPath),
                        systemImage: SFSymbols.folder.rawValue
                    )
                })
                Text(
                    // swiftlint:disable:next line_length
                    "**Private encryption secret used to encrypt all data sent to the server. This can be any suitably un-guessable string of bytes.**"
                )
                SecureField("Remote Encryption Secret", text: $viewModel.gcpServerEncryptionSecret)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .encryptionSecret)
            }
            TCSyncServiceButtonSectionView(
                buttonTitle: viewModel.buttonTitle(),
                action: completeAction,
                isDisabled: isLoading
            )
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                KeyboardToolbarView(
                    onPrevious: calculatePreviousField,
                    onNext: calculateNextField,
                    onDismiss: onDismissKeyboard
                )
            }
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
