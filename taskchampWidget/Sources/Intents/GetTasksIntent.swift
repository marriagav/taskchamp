import AppIntents
import taskchampShared
import WidgetKit

struct GetTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "Get tasks"
    static var description = IntentDescription("Retrieve pending tasks.")

    func perform() throws -> some IntentResult {
        do {
            let destinationPath = try FileService.shared.getDestinationPath()
            DBService.shared.setDbUrl(destinationPath)
            let tasks = try DBService.shared.getPendingTasks()
            print("tasks: \(tasks)")
            return .result()
        } catch {
            throw TCError.genericError("Error getting tasks \(error)")
            // return .result()
        }
    }
}
