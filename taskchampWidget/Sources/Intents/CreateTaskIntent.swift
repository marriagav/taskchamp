import AppIntents
import taskchampShared
import WidgetKit

struct CreateTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Task"
    static var description = IntentDescription("Create a task via natural language.")

    @Parameter(title: "Command line input") var taskInput: String

    init(taskInput: String) {
        self.taskInput = taskInput
    }

    init() {}

    func perform() async throws -> some IntentResult {
        let destinationPath = try FileService.shared.getDestinationPathForLocalReplica()
        try TaskchampionService.shared.setDbUrl(path: destinationPath)

        let task = NLPService.shared.createTask(from: taskInput)
        try TaskchampionService.shared.createTask(task)

        return .result()
    }
}
