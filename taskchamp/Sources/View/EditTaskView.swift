import SwiftUI

public struct EditTaskView: View {
    var task: Task

    @Environment(\.dismiss) var dismiss

    @State private var project = ""
    @State private var description = ""
    @State private var status: Task.Status = .pending
    @State private var priority: Task.Priority = .none

    @State private var didSetDate = false
    @State private var didSetTime = false
    @State private var isDateShowing = false
    @State private var isTimeShowing = false

    @State private var due: Date = .init()
    @State private var time: Date = .init()

    @State private var isShowingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    @FocusState private var isFocused: Bool

    var didChange: Bool {
        task.project ?? "" != project ||
            task.description != description ||
            task.status != status ||
            task.priority != (priority == Task.Priority.none ? nil : priority) ||
            task.due != Calendar.current.mergeDateWithTime(
                date: didSetDate ? due : nil,
                time: didSetTime ? time : nil
            )
    }

    init(task: Task) {
        description = task.description
        project = task.project ?? ""
        status = task.status
        priority = task.priority ?? .none
        if let due = task.due {
            didSetDate = true
            didSetTime = true
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: due)
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: due)
            self.due = calendar.date(from: dateComponents) ?? .init()
            time = calendar.date(from: timeComponents) ?? .init()
        }

        self.task = task
    }

    public var body: some View {
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
            Section {
                Button(action: {
                    do {
                        try DBService.shared.updatePendingTasks([task.uuid], withStatus: .completed)
                        dismiss()
                    } catch {
                        isShowingAlert = true
                        alertTitle = "There was an error"
                        alertMessage = "Task failed to update. Please try again."
                        print(error)
                    }
                }, label: {
                    Label("Mark as completed", systemImage: SFSymbols.checkmark.rawValue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .foregroundStyle(.white)
                })
                .buttonStyle(.borderedProminent)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
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
                        uuid: task.uuid,
                        project: project.isEmpty ? nil : project,
                        description: description,
                        status: status,
                        priority: priority == .none ? nil : priority,
                        due: finalDate
                    )

                    do {
                        try DBService.shared.updateTask(task)
                        dismiss()
                    } catch {
                        isShowingAlert = true
                        alertTitle = "There was an error"
                        alertMessage = "Task failed to update. Please try again."
                        print(error)
                    }
                }
                .disabled(!didChange)
                .bold()
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Menu {
                    Button(role: .destructive) {
                        do {
                            try DBService.shared.updatePendingTasks([task.uuid], withStatus: .deleted)
                            dismiss()
                        } catch {
                            isShowingAlert = true
                            alertTitle = "There was an error"
                            alertMessage = "Task failed to update. Please try again."
                            print(error)
                        }
                    } label: {
                        Label(
                            "Delete task",
                            systemImage: SFSymbols.trash.rawValue
                        )
                    }
                } label: {
                    Label("Delete", systemImage: SFSymbols.trash.rawValue)
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
        .navigationTitle(description)
    }
}
