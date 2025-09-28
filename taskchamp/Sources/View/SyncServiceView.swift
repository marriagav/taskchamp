import SwiftUI
import taskchampShared

public struct SyncServiceView: View {
    @Binding var isShowingSyncServiceModal: Bool
    @Binding var selectedSyncType: TaskchampionService.SyncType?
    @State private var pathStore = PathStore()

    var allValidCases: [TaskchampionService.SyncType] {
        TaskchampionService.SyncType.allCases.filter { filter in
            // TODO: Re-enable AWS and GCP when ready
            filter != .aws && filter != .gcp
        }
    }

    public var body: some View {
        NavigationStack(path: $pathStore.path) {
            Form {
                Section {
                    Text("Taskchampion can use a variety of sync services, select one below to begin the setup.")
                        .bold()
                        .foregroundStyle(.secondary)
                    Text(
                        // swiftlint:disable:next line_length
                        "If you are an existing user, you may need to reconfigure your sync service to ensure proper functionality."
                    )
                    .foregroundStyle(.secondary)
                }
                Section {
                    ForEach(allValidCases, id: \.self) { syncType in
                        Button {
                            pathStore.path.append(syncType)
                        } label: {
                            HStack {
                                Text(
                                    TaskchampionService.shared.getSyncServiceFromType(syncType)
                                        .settingName
                                )
                                if syncType == selectedSyncType {
                                    Spacer()
                                    Image(systemName: SFSymbols.checkmark.rawValue)
                                }
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isShowingSyncServiceModal = false
                    }
                }
            }
            .navigationTitle("Sync Service")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: TaskchampionService.SyncType.self) { syncType in
                switch syncType {
                case .remote:
                    RemoteSettingsView(
                        isShowingSyncServiceModal: $isShowingSyncServiceModal,
                        selectedSyncType: $selectedSyncType
                    )
                case .aws:
                    AwsSettingsView(
                        isShowingSyncServiceModal: $isShowingSyncServiceModal,
                        selectedSyncType: $selectedSyncType
                    )
                case .gcp:
                    GcpSettingsView(
                        isShowingSyncServiceModal: $isShowingSyncServiceModal,
                        selectedSyncType: $selectedSyncType
                    )
                case .local:
                    ICloudSettingsView(
                        isShowingSyncServiceModal: $isShowingSyncServiceModal,
                        selectedSyncType: $selectedSyncType
                    )
                case .none:
                    NoSyncServiceView(
                        isShowingSyncServiceModal: $isShowingSyncServiceModal,
                        selectedSyncType: $selectedSyncType
                    )
                }
            }
            .environment(pathStore)
        }
    }
}
