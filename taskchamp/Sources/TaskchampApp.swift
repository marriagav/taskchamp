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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // swiftlint:disable:next force_unwrapping
        .modelContainer(swiftDataService.container!)
    }
}
