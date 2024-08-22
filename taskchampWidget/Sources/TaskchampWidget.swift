import SwiftUI
import taskchampShared
import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in _: Context) -> TaskEntry {
        TaskEntry(date: Date(), task: Task(uuid: "test", description: "test", status: .pending))
    }

    func getSnapshot(in _: Context, completion: @escaping (TaskEntry) -> Void) {
        let entry = TaskEntry(date: Date(), task: Task(uuid: "test", description: "test", status: .pending))
        completion(entry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let entry = TaskEntry(date: Date(), task: Task(uuid: "test", description: "test", status: .pending))
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let task: Task
}

struct TaskchampWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text(entry.task.description)
                .font(.title)
                .padding()
            Text(entry.task.project ?? "")
                .font(.subheadline)
                .padding()
        }
    }
}

struct TaskchampWidget: Widget {
    let kind: String = "TaskchampWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TaskchampWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Taskchamp")
        .description("Keep track of your tasks")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
