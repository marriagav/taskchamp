import SwiftUI
import taskchampShared

public struct TaskCellView: View {
    let task: TCTask

    public var body: some View {
        VStack {
            HStack {
                Text(task.description)
                    .strikethrough(task.isCompleted || task.isDeleted, color: task.isDeleted ? .red : nil)
                    .foregroundStyle(task.isCompleted ? .secondary : task.isDeleted ? Color.red : .primary)
                Spacer()
                if let project = task.project {
                    Text(project)
                        .font(.subheadline.italic())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 3)
            HStack {
                if task.due != nil {
                    HStack(spacing: 4) {
                        Text(task.localDate)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if task.hasCriticalAlert {
                            Image(systemName: "bell.badge.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } else if task.hasCriticalAlert {
                    Image(systemName: "bell.badge.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Spacer()
                if let priority = task.priority {
                    Text(priority.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(priority == .high ? .red : priority == .medium ? .orange : .green)
                }
            }
        }
    }
}
