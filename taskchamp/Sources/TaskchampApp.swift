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
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                Task {
                    try await TaskchampionService.shared.sync()
                }
            }
        }
    }
}
