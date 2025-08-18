import Foundation
import taskchampShared

enum SyncServiceViewHelper {
    static func setReplica(syncType: TaskchampionService.SyncType) throws {
        let destinationPath = try FileService.shared.getDestinationPathForLocalReplica(syncType: syncType)
        try TaskchampionService.shared.setDbUrl(path: destinationPath)
    }

    static func setUserDefaults(syncType: TaskchampionService.SyncType) throws {
        let res = try JSONEncoder().encode(syncType)
        let defaults = UserDefaults(suiteName: "group.com.mav.taskchamp")
        guard let defaults else {
            throw TCError.genericError("No UserDefaults found")
        }
        defaults.set(res, forKey: "selectedSyncType")
    }
}
