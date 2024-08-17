import SwiftUI

public struct CreateTaskView: View {
    @Environment(\.dismiss) var dismiss

    @State private var project: String = ""
    @State private var description: String = ""
    @State private var status: Task.Status = .pending
    @State private var priority: Task.Priority = .none

    @State private var didSetDate: Bool = false
    @State private var didSetTime: Bool = false
    @State private var due: Date = .init()
    @State private var time: Date = .init()

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task name", text: $description)
                    TextField("Project", text: $project)
                }
                Section {
                    FormDateToggleButton(isOnlyTime: false, date: $due, isSet: $didSetDate)
                    FormDateToggleButton(isOnlyTime: true, date: $time, isSet: $didSetTime)
                }
                Section {
                    Picker("Priority", systemImage: SFSymbols.exclamationmark.rawValue, selection: $priority) {
                        Text(Task.Priority.none.rawValue.capitalized)
                        Divider()
                        ForEach(Task.Priority.allCases, id: \.self) { priority in
                            if priority != .none {
                                Text(priority.rawValue.capitalized)
                            }
                        }
                    }
                }
            }.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let date: Date? = didSetDate ? due : nil
                        let time: Date? = didSetTime ? time : nil
                        let finalDate = Calendar.current.mergeDateWithTime(date: date, time: time)

                        let task = Task(
                            uuid: UUID().description,
                            project: project.isEmpty ? nil : project,
                            description: description,
                            status: status,
                            priority: priority == .none ? nil : priority,
                            due: finalDate
                        )

                        do {
                            try DBService.shared.createTask(task)
                            dismiss()
                        } catch {
                            print(error)
                        }
                    }
                    .bold()
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("New Task")
        }
    }
}
