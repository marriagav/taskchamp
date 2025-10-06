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

    init() {
        // swiftlint:disable:next force_try
        modelContainer = try! ModelContainer(for: TCFilter.self, TCTag.self)
        nlpService.container = modelContainer
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
