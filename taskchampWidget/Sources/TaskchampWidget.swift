import SwiftUI
import taskchampShared
import WidgetKit

struct Provider: AppIntentTimelineProvider {
    @MainActor
    func placeholder(in _: Context) -> TaskEntry {
        let tasks = getTasks()
        return TaskEntry(date: Date(), title: "My tasks", tasks: tasks, filterId: nil)
    }

    @MainActor
    func snapshot(for configuration: TaskchampWidgetIntent, in _: Context) async -> TaskEntry {
        let filter = resolveFilter(from: configuration)
        let tasks = getTasks(filter: filter)
        return TaskEntry(date: Date(), title: configuration.widgetTitle, tasks: tasks, filterId: configuration.filter?.id)
    }

    @MainActor
    func timeline(for configuration: TaskchampWidgetIntent, in _: Context) async -> Timeline<TaskEntry> {
        let filter = resolveFilter(from: configuration)
        let tasks = getTasks(filter: filter)
        let entry = TaskEntry(date: Date(), title: configuration.widgetTitle, tasks: tasks, filterId: configuration.filter?.id)
        return Timeline(entries: [entry], policy: .atEnd)
    }

    private func resolveFilter(from configuration: TaskchampWidgetIntent) -> TCFilter {
        guard let filterEntity = configuration.filter,
              let filter = getFilterFromUserDefaults(id: filterEntity.id) else {
            return .defaultFilter
        }
        return filter
    }

    @MainActor
    func getTasks(filter: TCFilter = .defaultFilter) -> [TCTask] {
        do {
            let localReplicaPath = try FileService.shared.getDestinationPathForLocalReplica()
            try TaskchampionService.shared
                .setDbUrl(
                    path: localReplicaPath
                )
            Task {
                try await TaskchampionService.shared.sync()
            }
            return try TaskchampionService.shared.getTasks(filter: filter)
        } catch {
            print("Error getting tasks \(error)")
            return []
        }
    }
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let title: String
    let tasks: [TCTask]
    let filterId: String?
}

struct TaskchampWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var filterURL: URL {
        let id = entry.filterId ?? "default"
        return URL(string: "taskchamp://filter/\(id)")!
    }

    var body: some View {
        VStack(spacing: 10) {
            if family != .systemSmall {
                HStack {
                    Text(entry.title)
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
        .widgetURL(filterURL)
        .containerBackground(.background, for: .widget)
    }
}

struct TaskchampWidget: Widget {
    let kind: String = "TaskchampWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: TaskchampWidgetIntent.self, provider: Provider()) { entry in
            TaskchampWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Taskchamp")
        .description("Keep track of your tasks")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
