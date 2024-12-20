import SwiftData
import SwiftUI
import taskchampShared

@main
struct TaskchampApp: App {
    let notificationsService = NotificationService.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: TCFilter.self)
    }
}
