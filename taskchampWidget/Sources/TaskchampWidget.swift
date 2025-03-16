import SwiftUI
import taskchampShared
import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in _: Context) -> TaskEntry {
        let tasks = getTasks()
        let entry = TaskEntry(date: Date(), tasks: tasks)
        return entry
    }

    func getSnapshot(in _: Context, completion: @escaping (TaskEntry) -> Void) {
        let tasks = getTasks()
        let entry = TaskEntry(date: Date(), tasks: tasks)
        completion(entry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let tasks = getTasks()
        let entry = TaskEntry(date: Date(), tasks: tasks)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    func getTasks() -> [TCTask] {
        do {
            let destinationPath = try FileService.shared.getDestinationPath()
            DBServiceDEPRECATED.shared.setDbUrl(destinationPath)
            let tasks = try DBServiceDEPRECATED.shared.getTasks()
            return tasks
        } catch {
            print("Error getting tasks \(error)")
            return []
        }
    }
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [TCTask]
}

struct TaskchampWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 10) {
            if family != .systemSmall {
                HStack {
                    Text("My tasks")
                        .bold()
                        .foregroundStyle(.indigo)
                        .font(family == .systemLarge ? .title2 : .body)
                    Spacer()
                    Link(destination: TCTask.newTaskUrl) {
                        Image(systemName: SFSymbols.plusCircleFill.rawValue)
                            .font(family == .systemLarge ? .title : .title2)
                    }
                    .foregroundStyle(.indigo)
                }
            }
            if entry.tasks.isEmpty {
                VStack {
                    Spacer()
                    VStack {
                        Image(systemName: SFSymbols.partyPopperFill.rawValue)
                            .font(.largeTitle)
                            .foregroundStyle(.indigo)
                        Text("All tasks done!")
                            .bold()
                    }
                    .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                ViewThatFits {
                    if family == .systemLarge {
                        TasksThatFitView(entry: entry, items: 9, family: family)
                        TasksThatFitView(entry: entry, items: 8, family: family)
                        TasksThatFitView(entry: entry, items: 7, family: family)
                    }
                    if family == .systemMedium {
                        TasksThatFitView(entry: entry, items: 4, family: family)
                        TasksThatFitView(entry: entry, items: 3, family: family)
                    }
                    if family == .systemSmall {
                        TasksThatFitView(entry: entry, items: 4, family: family)
                    }
                }
                if family != .systemSmall {
                    Spacer()
                }
            }
        }
        .containerBackground(.background, for: .widget)
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
