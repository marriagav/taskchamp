import SwiftUI
import taskchampShared
import WidgetKit

struct TasksThatFitView: View {
    var family: WidgetFamily
    var tasks: [Task]

    init(entry: Provider.Entry, items: Int, family: WidgetFamily) {
        tasks = Array(entry.tasks.prefix(items))
        self.family = family
    }

    var body: some View {
        VStack {
            ForEach(tasks, id: \.uuid) { task in
                VStack {
                    HStack(spacing: 10) {
                        Toggle(
                            isOn: task.isCompleted,
                            intent: CompleteTaskIntent()
                        ) {
                            HStack {
                                Text(task.description)
                                    .lineLimit(1)
                                Spacer()
                                if family != .systemSmall {
                                    Text(task.localDateShort)
                                        .lineLimit(1)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .toggleStyle(CheckToggleStyle(priority: task.priority ?? .none))
                    }
                    if task != tasks.last {
                        Divider()
                    }
                }
            }
        }
    }
}
