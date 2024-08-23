import SwiftUI
import taskchampShared
import WidgetKit

struct TasksThatFitView: View {
    var family: WidgetFamily
    var tasks: [TCTask]

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
                            intent: CompleteTaskIntent(taskId: task.uuid)
                        ) {
                            Link(destination: task.url) {
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

struct CheckToggleStyle: ToggleStyle {
    let priority: TCTask.Priority
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Button {
                configuration.isOn.toggle()
            } label: {
                Image(
                    systemName: configuration.isOn ? SFSymbols.checkmarkCircleFill.rawValue : SFSymbols.circle
                        .rawValue
                )
                .foregroundStyle(
                    priority == .high ? .red : priority == .medium ? .orange : priority == .low ?
                        .green : .secondary
                )
                .accessibility(label: Text(configuration.isOn ? "Checked" : "Unchecked"))
                .imageScale(.medium)
            }
            Spacer()
            configuration.label
                .foregroundStyle(
                    configuration.isOn ? .secondary :
                        .primary
                )
        }
        .buttonStyle(.plain)
    }
}
