import SwiftUI
import Taskchampion

// MARK: - SyncServiceProtocol

public protocol SyncServiceProtocol {
    static var syncServiceType: TaskchampionService.SyncType { get }
    static var settingName: String { get }
    static var errorTitle: String { get }
    static var errorMessage: String { get }
    static func sync(replica: Replica) async throws -> Bool
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

    @MainActor
    public static func sync(replica: Replica) async throws -> Bool {
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

    @MainActor
    public static func sync(replica: Replica) async throws -> Bool {
        do {
            let icloudPath = try FileService.shared.getDestinationPathForICloudServer()
            return await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let synced = replica.sync_local_server(icloudPath)
                    continuation.resume(returning: synced)
                }
            }
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
        return UserDefaultsManager.shared.getValue(forKey: .remoteServerUrl)
    }

    public static func getRemoteClientId() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .remoteServerClientId)
    }

    public static func getRemoteEncryptionSecret() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .remoteServerEncryptionSecret)
    }

    public static func isAvailable() -> Bool {
        return getRemoteServerUrl() != nil &&
            getRemoteClientId() != nil &&
            getRemoteEncryptionSecret() != nil
    }

    @MainActor
    public static func sync(replica: Replica) async throws -> Bool {
        // swiftlint:disable all
        guard let remoteServerUrl = getRemoteServerUrl(),
              let remoteClientId = getRemoteClientId(),
              let remoteEncryptionSecret = getRemoteEncryptionSecret() else
        {
            // swiftlint:enable all
            throw TCError.genericError("Remote server configuration is incomplete")
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let synced = replica.sync_remote_server(
                    remoteServerUrl.intoRustString(),
                    remoteClientId.intoRustString(),
                    remoteEncryptionSecret.intoRustString()
                )
                continuation.resume(returning: synced)
            }
        }
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
        return UserDefaultsManager.shared.getValue(forKey: .gcpServerBucket)
    }

    public static func getGcpCredentialPath() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .gcpServerCredentialPath)
    }

    public static func getGcpEncryptionSecret() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .gcpServerEncryptionSecret)
    }

    public static func isAvailable() -> Bool {
        return getGcpBucket() != nil &&
            getGcpEncryptionSecret() != nil
    }

    @MainActor
    public static func sync(replica: Replica) async throws -> Bool {
        // swiftlint:disable all
        guard let bucket = getGcpBucket(),
              let encryptionSecret = getGcpEncryptionSecret() else
        {
            // swiftlint:enable all
            throw TCError.genericError("GCP configuration is incomplete")
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let synced = replica.sync_gcp(
                    bucket.intoRustString(),
                    getGcpCredentialPath()?.intoRustString(),
                    encryptionSecret.intoRustString()
                )
                continuation.resume(returning: synced)
            }
        }
    }
}

public class AwsSyncService: SyncServiceProtocol {
    public static let syncServiceType: TaskchampionService.SyncType = .aws
    public static let settingName = "S3"
    public static let errorTitle = "There was an error"
    public static let errorMessage =
        "Make sure that you have the correct S3 configuration"

    public static func getAwsBucket() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .awsServerBucket)
    }

    public static func getAwsRegion() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .awsServerRegion)
    }

    public static func getAwsEndpointUrl() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .awsServerEndpointUrl)
    }

    public static func getAwsForcePathStyle() -> Bool {
        return UserDefaultsManager.shared.getValue(forKey: .awsServerForcePathStyle) ?? false
    }

    public static func getAwsAccessKeyId() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .awsServerAccessKeyId)
    }

    public static func getAwsSecretAccessKey() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .awsServerSecretAccessKey)
    }

    public static func getAwsEncryptionSecret() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .awsServerEncryptionSecret)
    }

    private init() {}

    public static func isAvailable() -> Bool {
        return getAwsBucket() != nil &&
            getAwsAccessKeyId() != nil &&
            getAwsSecretAccessKey() != nil &&
            getAwsEncryptionSecret() != nil
    }

    @MainActor
    public static func sync(replica: Replica) async throws -> Bool {
        // swiftlint:disable all
        guard let bucket = getAwsBucket(),
              let accessKeyId = getAwsAccessKeyId(),
              let secretAccessKey = getAwsSecretAccessKey(),
              let encryptionSecret = getAwsEncryptionSecret() else
        {
            // swiftlint:enable all
            throw TCError.genericError("S3 configuration is incomplete")
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let synced = replica.sync_aws(
                    nonEmptyString(getAwsRegion())?.intoRustString(),
                    bucket.intoRustString(),
                    nonEmptyString(getAwsEndpointUrl())?.intoRustString(),
                    getAwsForcePathStyle(),
                    accessKeyId.intoRustString(),
                    secretAccessKey.intoRustString(),
                    encryptionSecret.intoRustString()
                )
                continuation.resume(returning: synced)
            }
        }
    }

    private static func nonEmptyString(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return value
    }
}
