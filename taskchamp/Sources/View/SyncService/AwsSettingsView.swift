import SwiftUI
import taskchampShared

@Observable
class AwsSettingsViewModel: UseSyncServiceViewModel {
    var isShowingAlert = false
    var isImporting = false

    var awsServerBucket = ""
    var awsServerRegion = ""
    var awsServerEndpointUrl = ""
    var awsServerForcePathStyle = false
    var awsServerAccessKeyId = ""
    var awsServerSecretAccessKey = ""
    var awsServerEncryptionSecret = ""

    var syncType: TaskchampionService.SyncType {
        .aws
    }

    var summary: String {
        "S3 sync connects to an S3 service to synchronize your tasks across devices."
    }

    func buttonTitle(for _: TaskchampionService.SyncType? = nil) -> String {
        return "Save S3 Sync"
    }

    func setOtherUserDefaults() {
        UserDefaultsManager.shared.set(value: awsServerBucket, forKey: .awsServerBucket)
        UserDefaultsManager.shared.set(value: awsServerRegion, forKey: .awsServerRegion)
        UserDefaultsManager.shared.set(value: awsServerEndpointUrl, forKey: .awsServerEndpointUrl)
        UserDefaultsManager.shared.set(value: awsServerForcePathStyle, forKey: .awsServerForcePathStyle)
        UserDefaultsManager.shared.set(value: awsServerAccessKeyId, forKey: .awsServerAccessKeyId)
        UserDefaultsManager.shared.set(value: awsServerSecretAccessKey, forKey: .awsServerSecretAccessKey)
        UserDefaultsManager.shared.set(value: awsServerEncryptionSecret, forKey: .awsServerEncryptionSecret)
    }

    func onAppear() {
        if let bucket = AwsSyncService.getAwsBucket() {
            awsServerBucket = bucket
        }

        if let region = AwsSyncService.getAwsRegion() {
            awsServerRegion = region
        }

        if let endpointUrl = AwsSyncService.getAwsEndpointUrl() {
            awsServerEndpointUrl = endpointUrl
        }

        awsServerForcePathStyle = AwsSyncService.getAwsForcePathStyle()

        if let accessKeyId = AwsSyncService.getAwsAccessKeyId() {
            awsServerAccessKeyId = accessKeyId
        }

        if let secretAccessKey = AwsSyncService.getAwsSecretAccessKey() {
            awsServerSecretAccessKey = secretAccessKey
        }

        if let encryptionSecret = AwsSyncService.getAwsEncryptionSecret() {
            awsServerEncryptionSecret = encryptionSecret
        }
    }
}

struct AwsSettingsView: View, UseKeyboardToolbar {
    @Binding var isShowingSyncServiceModal: Bool
    @Binding var selectedSyncType: TaskchampionService.SyncType?
    @Environment(PathStore.self) var pathStore: PathStore

    @State private var viewModel = AwsSettingsViewModel()
    @State private var isLoading = false
    @FocusState var focusedField: FormField?
    enum FormField {
        case bucket
        case region
        case endpointUrl
        case accessKeyId
        case secretAccessKey
        case encryptionSecret
    }

    func calculateNextField() {
        switch focusedField {
        case .bucket:
            focusedField = .region
        case .region:
            focusedField = .endpointUrl
        case .endpointUrl:
            focusedField = .accessKeyId
        case .accessKeyId:
            focusedField = .secretAccessKey
        case .secretAccessKey:
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
        case .region:
            focusedField = .bucket
        case .accessKeyId:
            focusedField = .endpointUrl
        case .endpointUrl:
            focusedField = .region
        case .secretAccessKey:
            focusedField = .accessKeyId
        case .encryptionSecret:
            focusedField = .secretAccessKey
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
                    "**Region in which the S3 bucket is located. Optional for some S3 services.**"
                )
                TextField("Region", text: $viewModel.awsServerRegion)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .region)
                Text(
                    "**Endpoint URL for an S3 service. Leave blank when using Amazon S3.**"
                )
                TextField("Endpoint URL", text: $viewModel.awsServerEndpointUrl)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .endpointUrl)
                Toggle("Force path-style URLs", isOn: $viewModel.awsServerForcePathStyle)
                Text(
                    "**Bucket in which to store the task data. This bucket must not be used for any other purpose.**"
                )
                TextField("S3 bucket", text: $viewModel.awsServerBucket)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .bucket)
                Text(
                    "**A pair of S3 access key ID and secret access key.**"
                )
                TextField("S3 Access Key ID", text: $viewModel.awsServerAccessKeyId)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .accessKeyId)
                SecureField("S3 Secret Access Key", text: $viewModel.awsServerSecretAccessKey)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .secretAccessKey)
                Text(
                    // swiftlint:disable:next line_length
                    "**Private encryption secret used to encrypt all data sent to the server. This can be any suitably un-guessable string of bytes.**"
                )
                SecureField("Remote Encryption Secret", text: $viewModel.awsServerEncryptionSecret)
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
                message: Text("Make sure that you set the S3 server configuration"),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationTitle("S3 Sync")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
    }
}
