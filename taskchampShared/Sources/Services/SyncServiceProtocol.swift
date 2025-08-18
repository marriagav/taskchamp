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

    public static func sync(replica _: Replica) throws -> Bool {
        return true // No sync needed for NoSyncService
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
        do {
            if let data = UserDefaults(suiteName: "group.com.mav.taskchamp")?.data(forKey: "remoteServerUrl") {
                let res = try JSONDecoder().decode(String.self, from: data)
                return res
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    public static func getRemoteClientId() -> String? {
        do {
            if let data = UserDefaults(suiteName: "group.com.mav.taskchamp")?.data(forKey: "remoteServerClientId") {
                let res = try JSONDecoder().decode(String.self, from: data)
                return res
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    public static func getRemoteEncryptionSecret() -> String? {
        do {
            // swiftlint:disable all
            if let data = UserDefaults(suiteName: "group.com.mav.taskchamp")?
                .data(forKey: "remoteServerEncryptionSecret")
            {
                // swiftlint:enable all
                let res = try JSONDecoder().decode(String.self, from: data)
                return res
            } else {
                return nil
            }
        } catch {
            return nil
        }
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
        do {
            if let data = UserDefaults(suiteName: "group.com.mav.taskchamp")?.data(forKey: "gcpServerBucket") {
                let res = try JSONDecoder().decode(String.self, from: data)
                return res
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    public static func getGcpCredentialPath() -> String? {
        do {
            if let data = UserDefaults(suiteName: "group.com.mav.taskchamp")?.data(forKey: "gcpServerCredentialPath") {
                let res = try JSONDecoder().decode(String.self, from: data)
                return res
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    public static func getGcpEncryptionSecret() -> String? {
        do {
            // swiftlint:disable all
            if let data = UserDefaults(suiteName: "group.com.mav.taskchamp")?
                .data(forKey: "gcpServerEncryptionSecret")
            {
                // swiftlint:enable all
                let res = try JSONDecoder().decode(String.self, from: data)
                return res
            } else {
                return nil
            }
        } catch {
            return nil
        }
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

    private init() {}

    public static func isAvailable() -> Bool {
        return false // TODO: Implement AWS Sync Service
    }

    public static func sync(replica _: Replica) throws -> Bool {
        return false // TODO: Implement AWS Sync Service
    }
}
