import SwiftUI

public struct TaskCellView: View {
    private let task: Task

    init(task: Task) {
        self.task = task
    }

    public var body: some View {
        VStack {
            HStack {
                // Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                //     .font(.largeTitle)
                Text(task.description)
                    .font(.headline)
                Spacer()
                if let priority = task.priority {
                    Text(priority.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(priority == .high ? .red : priority == .medium ? .orange : .green)
                }
            }
            .padding(.vertical, 5)
            HStack {
                if let due = task.due {
                    Text(task.localDate)
                        .font(.subheadline)
                }
                Spacer()
                if let project = task.project {
                    Text(project)
                        .font(.subheadline.italic())
                }
            }
        }
    }
}
