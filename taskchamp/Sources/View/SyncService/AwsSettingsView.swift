import SwiftUI
import taskchampShared

@Observable
class AwsSettingsViewModel: UseSyncServiceViewModel {
    var isShowingAlert = false
    var isImporting = false

    var awsServerBucket: String = ""
    var awsServerRegion: String = ""
    var awsServerAccessKeyId: String = ""
    var awsServerSecretAccessKey: String = ""
    var awsServerEncryptionSecret: String = ""

    var syncType: TaskchampionService.SyncType {
        .aws
    }

    var summary: String {
        "AWS Sync works by connecting to a S3 bucket that will handle the synchronization of your tasks across devices."
    }

    func buttonTitle(for _: TaskchampionService.SyncType? = nil) -> String {
        return "Save Aws Sync"
    }

    func setOtherUserDefaults() {
        UserDefaultsManager.shared.set(value: awsServerBucket, forKey: .awsServerBucket)
        UserDefaultsManager.shared.set(value: awsServerRegion, forKey: .awsServerRegion)
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

struct AwsSettingsView: View {
    @Binding var isShowingSyncServiceModal: Bool
    @Binding var selectedSyncType: TaskchampionService.SyncType?
    @Environment(PathStore.self) var pathStore: PathStore

    @State private var viewModel = AwsSettingsViewModel()
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
                    "**AWS region in which the S3 bucket is located.**"
                )
                TextField("AWS Region", text: $viewModel.awsServerRegion)
                    .autocapitalization(.none)
                Text(
                    "**Bucket in which to store the task data. This bucket must not be used for any other purpose.**"
                )
                TextField("AWS S3 bucket", text: $viewModel.awsServerBucket)
                    .autocapitalization(.none)
                Text(
                    "**A pair of access key ID and secret access key.**"
                )
                TextField("AWS Access Key ID", text: $viewModel.awsServerAccessKeyId)
                    .autocapitalization(.none)
                SecureField("AWS Secret Access Key", text: $viewModel.awsServerSecretAccessKey)
                    .autocapitalization(.none)
                Text(
                    // swiftlint:disable:next line_length
                    "**Private encryption secret used to encrypt all data sent to the server. This can be any suitably un-guessable string of bytes.**"
                )
                SecureField("Remote Encryption Secret", text: $viewModel.awsServerEncryptionSecret)
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
                message: Text("Make sure that you set the AWS server configurations"),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationTitle("Amazon Web Services Sync")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
    }
}
