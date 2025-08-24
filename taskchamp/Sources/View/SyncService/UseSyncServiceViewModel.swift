import SwiftUI
import taskchampShared

protocol UseSyncServiceViewModel {
    var summary: String { get }
    var instructions: [String] { get }
    var syncType: TaskchampionService.SyncType { get }

    func buttonTitle(for selectedSyncType: TaskchampionService.SyncType?) -> String

    func setReplica() throws
    func setUserDefaults() throws

    func setOtherUserDefaults()

    func completeAction(
        isShowingSyncServiceModal: Binding<Bool>,
        selectedSyncType: Binding<TaskchampionService.SyncType?>,
        isShowingAlert: Binding<Bool>
    )
}

extension UseSyncServiceViewModel {
    var instructions: [String] {
        []
    }

    func setReplica() throws {
        let destinationPath = try FileService.shared.getDestinationPathForLocalReplica(syncType: syncType)
        try TaskchampionService.shared.setDbUrl(path: destinationPath)
    }

    func setUserDefaults() throws {
        try UserDefaultsManager.shared.setEncodableValue(syncType, forKey: .selectedSyncType)
    }

    func setOtherUserDefaults() {
        // Default implementation does nothing
    }

    func completeAction(
        isShowingSyncServiceModal: Binding<Bool>,
        selectedSyncType: Binding<TaskchampionService.SyncType?>,
        isShowingAlert: Binding<Bool>
    ) {
        setOtherUserDefaults()
        do {
            try setReplica()
            try TaskchampionService.shared.sync(syncType: syncType)
            let needsSync = TaskchampionService.shared.needToSync
            if needsSync {
                isShowingAlert.wrappedValue = true
                return
            }
        } catch {
            isShowingAlert.wrappedValue = true
            return
        }
        do {
            try setUserDefaults()
        } catch {
            isShowingAlert.wrappedValue = true
            return
        }

        selectedSyncType.wrappedValue = syncType
        isShowingSyncServiceModal.wrappedValue = false
    }
}
