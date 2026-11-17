import Foundation
import Taskchampion
import WidgetKit

// MARK: - Sync queue

extension TaskchampionService {
    @MainActor
    public func sync(syncType: SyncType, onSync: @escaping () -> Void = {}) async throws {
        try await requestSync(syncType: syncType, onSync: onSync)
    }

    @MainActor
    public func sync(onSync: @escaping () -> Void = {}) async throws {
        try await requestSync(syncType: nil, onSync: onSync)
    }

    /// Asks for a sync with `syncType`, or with the user's selected sync service when nil, and
    /// returns once a sync that started after this request has finished. `onSync` runs at that point.
    ///
    /// Only one sync runs at a time. Running two at once on the same database is unsafe and was
    /// seen in crash reports. Requests made while a sync is running are merged into a single
    /// follow-up sync, so a burst of edits leads to at most one extra sync.
    @MainActor
    private func requestSync(syncType: SyncType?, onSync: @escaping () -> Void) async throws {
        // A sync started in the background can be suspended halfway while holding the database
        // lock, which gets the app killed. Remember it and run it once the app is active again.
        guard isSyncAllowed else {
            hasDeferredSync = true
            onSync()
            return
        }
        guard replica != nil else {
            throw TCError.genericError("Database not set")
        }

        await withCheckedContinuation { continuation in
            var request = pendingSync ?? PendingSync()
            if let syncType {
                request.syncType = syncType
            }
            request.onSyncCallbacks.append(onSync)
            request.waiters.append(continuation)
            pendingSync = request
            startSyncRunnerIfNeeded()
        }
    }

    /// Starts the loop that works through pending syncs one at a time, unless it's already running.
    @MainActor
    private func startSyncRunnerIfNeeded() {
        guard syncRunner == nil else { return }
        syncRunner = _Concurrency.Task { @MainActor in
            while let request = pendingSync {
                pendingSync = nil
                if isSyncAllowed {
                    await runSync(syncType: request.syncType)
                } else {
                    // The app went to the background before this sync started.
                    hasDeferredSync = true
                }
                request.onSyncCallbacks.forEach { $0() }
                request.waiters.forEach { $0.resume() }
            }
            syncRunner = nil
        }
    }

    /// Performs a single sync. Only called from the sync runner, so syncs never overlap.
    @MainActor
    private func runSync(syncType: SyncType?) async {
        guard let replica else {
            needToSync = true
            return
        }

        let syncType: SyncType = syncType ?? FileService.shared.getSelectedSyncType() ?? .none
        let syncService = getSyncServiceFromType(syncType)

        // Keep the app running until this sync finishes, even if the user leaves the app.
        let endSyncActivity = beginSyncActivity?()
        defer { endSyncActivity?() }

        do {
            let synced = try await syncService.sync(replica: replica)
            needToSync = !synced
            if synced {
                // A successful sync uploads every local change, including ones from extensions.
                hasDeferredSync = false
            }
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            needToSync = true
        }
    }
}
