import SwiftData
import SwiftUI
import taskchampShared

@main
struct TaskchampApp: App {
    @Environment(\.scenePhase) var scenePhase

    let notificationsService = NotificationService.shared
    let taskchampionService = TaskchampionService.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: TCFilter.self)
    }
}
