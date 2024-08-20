import SwiftUI

public struct CreateTaskView: View {
    @Environment(\.dismiss) var dismiss

    @State private var project: String = ""
    @State private var description: String = ""
    @State private var status: Task.Status = .pending
    @State private var priority: Task.Priority = .none

    @State private var didSetDate: Bool = false
    @State private var didSetTime: Bool = false
    @State private var isDateShowing: Bool = false
    @State private var isTimeShowing: Bool = false

    @State private var due: Date = .init()
    @State private var time: Date = .init()

    @State private var isShowingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    @FocusState private var isFocused: Bool

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task name", text: $description)
                        .focused($isFocused)
                    TextField("Project", text: $project)
                        .focused($isFocused)
                }
                Section {
                    FormDateToggleButton(
                        isOnlyTime: false,
                        date: $due,
                        isSet: $didSetDate,
                        isDateShowing: $isDateShowing
                    )
                    FormDateToggleButton(
                        isOnlyTime: true,
                        date: $time,
                        isSet: $didSetTime,
                        isDateShowing: $isTimeShowing
                    )
                }
                Section {
                    Picker("Priority", systemImage: SFSymbols.exclamationmark.rawValue, selection: $priority) {
                        Text(Task.Priority.none.rawValue.capitalized)
                            .tag(Task.Priority.none)
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
                        if description.isEmpty {
                            isShowingAlert = true
                            alertTitle = "Missing field"
                            alertMessage = "Please enter a task name"
                            return
                        }

                        let date: Date? = didSetDate ? due : nil
                        let time: Date? = didSetTime ? time : nil
                        let finalDate = Calendar.current.mergeDateWithTime(date: date, time: time)

                        let task = Task(
                            uuid: UUID().uuidString,
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
                            isShowingAlert = true
                            alertTitle = "There was an error"
                            alertMessage = "Task failed to create. Please try again."
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
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isFocused = false
                        }
                    }
                }
            }
            .onChange(
                of: didSetTime
            ) { _, newValue in
                if didSetTime {
                    didSetDate = true
                    isDateShowing = false
                    withAnimation {
                        isTimeShowing = newValue
                    }
                }
            }
            .onChange(
                of: didSetDate
            ) { _, newValue in
                if !didSetDate {
                    didSetTime = false
                    isTimeShowing = false
                } else if didSetDate, !didSetTime {
                    withAnimation {
                        isDateShowing = newValue
                    }
                }
            }
            .animation(.default, value: didSetDate)
            .animation(.default, value: didSetTime)
            .alert(isPresented: $isShowingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .navigationTitle("New Task")
        }
    }
}
