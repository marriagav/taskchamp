import SwiftUI

public struct CreateTaskView: View {
    // @State private var task: Task = .init(uuid: UUID().description, description: "", status: Task.Status.pending)

    @State private var uuid: String = UUID().description
    @State private var project: String = ""
    @State private var description: String = ""
    @State private var status: Task.Status = .pending
    @State private var priority: Task.Priority?
    @State private var due: Date = .init()
    @State private var time: Date = .init()

    public var body: some View {
        Form {
            Section {
                TextField("Task name", text: $description)
                TextField("Project", text: $project)
            }
            Section {
                FormDateToggleButton(isOnlyTime: false, date: $due)
                FormDateToggleButton(isOnlyTime: true, date: $time)
            }
            Section {
                Picker("Priority", systemImage: "exclamationmark", selection: $priority) {
                    ForEach(Task.Priority.allCases, id: \.self) { priority in
                        Text(priority.rawValue.capitalized)
                    }
                }
            }
        }
    }
}
