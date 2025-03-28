import AppIntents
import taskchampShared
import WidgetKit

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description = IntentDescription("The task is marked as completed.")

    @Parameter(title: "taskId") var taskId: String

    init(taskId: String) {
        self.taskId = taskId
    }

    init() {}

    func perform() async throws -> some IntentResult {
        let destinationPath = try FileService.shared.getDestinationPath()
        DBServiceDEPRECATED.shared.setDbUrl(destinationPath)

        try? DBServiceDEPRECATED.shared.togglePendingTasksStatus(uuids: [taskId])
        NotificationService.shared.removeNotifications(for: [taskId])

        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return .result()
    }
}
