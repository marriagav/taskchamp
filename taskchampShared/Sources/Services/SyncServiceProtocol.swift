import SwiftUI
import Taskchampion

// MARK: - SyncServiceProtocol

public protocol SyncServiceProtocol {
    static var syncServiceType: TaskchampionService.SyncType { get }
    static var settingName: String { get }
    static var errorTitle: String { get }
    static var errorMessage: String { get }
    static func sync(replica: Replica) throws -> Bool
    static func isAvailable() -> Bool
}

// MARK: - NoSyncService

public class NoSyncService: SyncServiceProtocol {
    public static let syncServiceType: TaskchampionService.SyncType = .none
    public static let settingName = "No Sync Service"
    public static let errorTitle = "Unexpected Error"
    public static let errorMessage = "Please try again later"

    private init() {}

    public static func isAvailable() -> Bool {
        return true
    }

    public static func sync(replica: Replica) throws -> Bool {
        return replica.sync_no_server()
    }
}

// MARK: - ICloudSyncService

public class ICloudSyncService: SyncServiceProtocol {
    public static let syncServiceType: TaskchampionService.SyncType = .local
    public static let settingName = "iCloud Sync"
    public static let errorTitle = "iCloud Required"
    public static let errorMessage =
        "In order to use Taskchamp with iCloud Sync, you require to have an iCloud account and iCloud Drive enabled"

    private init() {}

    public static func isAvailable() -> Bool {
        return FileService.shared.isICloudAvailable()
    }

    public static func sync(replica: Replica) throws -> Bool {
        do {
            let icloudPath = try FileService.shared.getDestinationPathForICloudServer()
            let synced = replica.sync_local_server(icloudPath)
            return synced
        } catch {
            throw TCError.genericError("Failed to sync with iCloud: \(error.localizedDescription)")
        }
    }
}

public class RemoteSyncService: SyncServiceProtocol {
    public static let syncServiceType: TaskchampionService.SyncType = .remote
    public static let settingName = "Taskchampion Sync Server"
    public static let errorTitle = "There was an error"
    public static let errorMessage =
        "Make sure that you have the `taskchampion-sync-server` running"

    private init() {}

    public static func getRemoteServerUrl() -> String? {
        let value: String? = UserDefaultsManager.shared.getValue(forKey: .remoteServerUrl)
        return value
    }

    public static func getRemoteClientId() -> String? {
        let value: String? = UserDefaultsManager.shared.getValue(forKey: .remoteServerClientId)
        return value
    }

    public static func getRemoteEncryptionSecret() -> String? {
        let value: String? = UserDefaultsManager.shared.getValue(forKey: .remoteServerEncryptionSecret)
        return value
    }

    public static func isAvailable() -> Bool {
        return getRemoteServerUrl() != nil &&
            getRemoteClientId() != nil &&
            getRemoteEncryptionSecret() != nil
    }

    public static func sync(replica: Replica) throws -> Bool {
        // swiftlint:disable all
        guard let remoteServerUrl = getRemoteServerUrl(),
              let remoteClientId = getRemoteClientId(),
              let remoteEncryptionSecret = getRemoteEncryptionSecret() else
        {
            // swiftlint:enable all
            throw TCError.genericError("Remote server configuration is incomplete")
        }
        let synced = replica.sync_remote_server(
            remoteServerUrl.intoRustString(),
            remoteClientId.intoRustString(),
            remoteEncryptionSecret.intoRustString()
        )
        return synced
    }
}

public class GcpSyncService: SyncServiceProtocol {
    public static let syncServiceType: TaskchampionService.SyncType = .gcp
    public static let settingName = "Google Cloud Platform"
    public static let errorTitle = "There was an error"
    public static let errorMessage =
        "Make sure that you have the correct GCP configuration"

    private init() {}

    public static func getGcpBucket() -> String? {
        let value: String? = UserDefaultsManager.shared.getValue(forKey: .gcpServerBucket)
        return value
    }

    public static func getGcpCredentialPath() -> String? {
        let value: String? = UserDefaultsManager.shared.getValue(forKey: .gcpServerCredentialPath)
        return value
    }

    public static func getGcpEncryptionSecret() -> String? {
        let value: String? = UserDefaultsManager.shared.getValue(forKey: .gcpServerEncryptionSecret)
        return value
    }

    public static func isAvailable() -> Bool {
        return getGcpBucket() != nil &&
            getGcpEncryptionSecret() != nil
    }

    public static func sync(replica: Replica) throws -> Bool {
        // swiftlint:disable all
        guard let bucket = getGcpBucket(),
              let encryptionSecret = getGcpEncryptionSecret() else
        {
            // swiftlint:enable all
            throw TCError.genericError("GCP configuration is incomplete")
        }
        let synced = replica.sync_gcp(
            bucket.intoRustString(),
            getGcpCredentialPath()?.intoRustString(),
            encryptionSecret.intoRustString()
        )
        return synced
    }
}

public class AwsSyncService: SyncServiceProtocol {
    public static let syncServiceType: TaskchampionService.SyncType = .gcp
    public static let settingName = "Amazon Web Services"
    public static let errorTitle = "There was an error"
    public static let errorMessage =
        "Make sure that you have the correct AWS configuration"

    // public static func getAwsBucket() -> String? {
    //     if let bucket = UserDefaults(suiteName: "group.com.mav.taskchamp")?.string(forKey: "awsServerBucket") {
    //         return bucket
    //     } else {
    //         return nil
    //     }
    // }
    //
    // public static func getAwsRegion() -> String? {
    //     if let region = UserDefaults(suiteName: "group.com.mav.taskchamp")?.string(forKey: "awsServerRegion") {
    //         return region
    //     } else {
    //         return nil
    //     }
    // }

    private init() {}

    public static func isAvailable() -> Bool {
        return false // TODO: Implement AWS Sync Service
    }

    public static func sync(replica _: Replica) throws -> Bool {
        // return replica.sync_aws()

        // let synced = replica.sync_aws(
        //     bucket.intoRustString(),
        //     getGcpCredentialPath()?.intoRustString(),
        //     encryptionSecret.intoRustString()
        // )
        // return synced
        //
        return false
    }
}
