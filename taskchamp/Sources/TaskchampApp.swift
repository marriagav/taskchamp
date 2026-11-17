import SwiftData
import SwiftUI
import taskchampShared

@main
struct TaskchampApp: App {
    @Environment(\.scenePhase) var scenePhase
    private var modelContainer: ModelContainer

    let notificationsService = NotificationService.shared
    let taskchampionService = TaskchampionService.shared
    let nlpService = NLPService.shared
    let swiftDataService = SwiftDataService.shared

    init() {
        // swiftlint:disable:next force_try
        modelContainer = try! ModelContainer(for: TCFilter.self, TCTag.self)
        swiftDataService.container = modelContainer
        taskchampionService.beginSyncActivity = Self.beginBackgroundSyncTask
    }

    /// Asks iOS for extra time to finish a sync if the user leaves the app mid-sync. Without it,
    /// the app can be suspended while holding the database lock, and iOS kills it (0xdead10cc).
    /// Returns a closure that ends the background task.
    private static func beginBackgroundSyncTask() -> () -> Void {
        var identifier = UIBackgroundTaskIdentifier.invalid
        identifier = UIApplication.shared.beginBackgroundTask(withName: "Taskchamp sync") {
            // Out of time. End the task so iOS doesn't kill the app for overrunning it.
            UIApplication.shared.endBackgroundTask(identifier)
            identifier = .invalid
        }
        return {
            guard identifier != .invalid else { return }
            UIApplication.shared.endBackgroundTask(identifier)
            identifier = .invalid
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // swiftlint:disable:next force_unwrapping
        .modelContainer(swiftDataService.container!)
    }
}
