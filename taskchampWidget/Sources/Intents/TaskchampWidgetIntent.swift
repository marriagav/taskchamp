import AppIntents
import taskchampShared
import WidgetKit

struct TaskchampWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Widget"
    static var description: IntentDescription = "Customize the widget title and filter."

    @Parameter(title: "Title", default: "My tasks")
    var widgetTitle: String

    @Parameter(title: "Filter")
    var filter: FilterAppEntity?

    init() {
        filter = .noFilter
    }

    init(widgetTitle: String, filter: FilterAppEntity?) {
        self.widgetTitle = widgetTitle
        self.filter = filter
    }
}
