import AppIntents
import taskchampShared
import WidgetKit

struct TaskchampWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Widget"
    static var description: IntentDescription = "Customize the widget title, filter, and completion message."

    /// Default message shown when the widget has no tasks to display.
    static let defaultAllDoneMessage = "All tasks done!"

    @Parameter(title: "Title", default: "My tasks")
    var widgetTitle: String

    @Parameter(title: "Filter")
    var filter: FilterAppEntity?

    @Parameter(title: "All Done Message", default: "All tasks done!")
    var allDoneMessage: String

    init() {
        filter = .noFilter
    }

    init(widgetTitle: String, filter: FilterAppEntity?, allDoneMessage: String = defaultAllDoneMessage) {
        self.widgetTitle = widgetTitle
        self.filter = filter
        self.allDoneMessage = allDoneMessage
    }

    /// The message to show when all tasks are done, falling back to the default if the user cleared the field.
    var resolvedAllDoneMessage: String {
        let trimmed = allDoneMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Self.defaultAllDoneMessage : trimmed
    }
}
