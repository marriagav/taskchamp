import SwiftUI
import taskchampShared
import WidgetKit

struct QuickAddCircularWidget: Widget {
    let kind: String = "QuickAddCircularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickAddProvider()) { _ in
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: SFSymbols.plus.rawValue)
                    .font(.title)
                    .fontWeight(.semibold)
            }
            .widgetURL(TCTask.newTaskUrl)
            .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Quick Add")
        .description("Quickly create a new task")
        .supportedFamilies([.accessoryCircular])
    }
}

private struct QuickAddProvider: TimelineProvider {
    func placeholder(in _: Context) -> QuickAddEntry {
        QuickAddEntry(date: Date())
    }

    func getSnapshot(in _: Context, completion: @escaping (QuickAddEntry) -> Void) {
        completion(QuickAddEntry(date: Date()))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<QuickAddEntry>) -> Void) {
        let entry = QuickAddEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

private struct QuickAddEntry: TimelineEntry {
    let date: Date
}
