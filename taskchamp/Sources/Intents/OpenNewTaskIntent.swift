import AppIntents
import taskchampShared

struct OpenNewTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Quick Add"
    static var description: IntentDescription = "Opens Taskchamp to create a new task."
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Content", default: "") var content: String

    @MainActor
    func perform() async throws -> some IntentResult {
        if !content.isEmpty {
            UserDefaultsManager.standard.set(value: content, forKey: .pendingNewTaskContent)
        }
        var urlString = "taskchamp://task/new"
        if
            !content.isEmpty,
            let encoded = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        {
            urlString += "?content=\(encoded)"
        }
        if let url = URL(string: urlString) {
            NotificationCenter.default.post(
                name: .TCTappedDeepLinkNotification,
                object: url
            )
        }
        return .result()
    }
}
