import AppIntents
import WidgetKit

struct TaskchampWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Widget"
    static var description: IntentDescription = "Customize the widget title and filter."

    @Parameter(title: "Title", default: "My tasks")
    var widgetTitle: String

    @Parameter(title: "Filter")
    var filter: FilterAppEntity?
}
