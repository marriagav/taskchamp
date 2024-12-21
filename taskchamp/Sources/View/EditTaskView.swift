import SwiftUI
import taskchampShared

public struct EditTaskView: View {
    @State var task: TCTask

    @Environment(\.dismiss) var dismiss

    @State private var project = ""
    @State private var description = ""
    @State private var status: TCTask.Status = .pending
    @State private var priority: TCTask.Priority = .none

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
            task.priority != (priority == TCTask.Priority.none ? nil : priority) ||
            task.due != Calendar.current.mergeDateWithTime(
                date: didSetDate ? due : nil,
                time: didSetTime ? time : nil
            )
    }

    init(task: TCTask) {
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
                    Text(TCTask.Priority.none.rawValue.capitalized)
                        .tag(TCTask.Priority.none)
                    Divider()
                    ForEach(TCTask.Priority.allCases, id: \.self) { priority in
                        if priority != .none {
                            Text(priority.rawValue.capitalized)
                        }
                    }
                }
            }
            Section {
                Button(action: {
                    do {
                        let newStatus: TCTask.Status = task.isCompleted ? .pending : task
                            .isDeleted ? .pending : .completed
                        try DBService.shared.updatePendingTasks(
                            [task.uuid],
                            withStatus: newStatus
                        )
                        if (newStatus == .completed) || (newStatus == .deleted) {
                            NotificationService.shared.deleteReminderForTask(task: task)
                        } else {
                            NotificationService.shared.createReminderForTask(task: task)
                        }
                        dismiss()
                    } catch {
                        isShowingAlert = true
                        alertTitle = "There was an error"
                        alertMessage = "Task failed to update. Please try again."
                        print(error)
                    }
                }, label: {
                    Label(
                        task.isDeleted ? "Restore task" : task.isCompleted ? "Mark as pending" : "Mark as completed",
                        systemImage: (task.isDeleted || task.isCompleted) ? SFSymbols.backArrow.rawValue : SFSymbols
                            .checkmark.rawValue
                    )
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

                    let task = TCTask(
                        uuid: task.uuid,
                        project: project.isEmpty ? nil : project,
                        description: description,
                        status: status,
                        priority: priority == .none ? nil : priority,
                        due: finalDate
                    )

                    do {
                        try DBService.shared.updateTask(task)
                        NotificationService.shared.createReminderForTask(task: task)
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
                Button {
                    let obsidianPath = UserDefaults.standard.string(forKey: "obsidianPath")
                    // TODO: Implement Obsidian path setter
                    guard let obsidianPath else {
                        isShowingAlert = true
                        alertTitle = "Obsidian path not set"
                        alertMessage = "Please set the Obsidian path in the settings"
                        return
                    }
                    if task.hasNote {
                        // TODO: Implement Obsidian note opener
                        print("Navigating to note: \(task.obsidianNote ?? "")")
                        return
                    }
                    let taskNote = "task-note: \(task.description.replace(" ", with: "-"))"
                    let newTask = TCTask(
                        uuid: task.uuid,
                        project: task.project,
                        description: task.description,
                        status: task.status,
                        priority: task.priority,
                        due: task.due,
                        obsidianNote: taskNote
                    )
                    do {
                        try DBService.shared.updateTask(newTask)
                        task = newTask
                        // TODO: Implement Obsidian note opener
                        print("Navigating to note: \(task.obsidianNote ?? "")")
                        return
                    } catch {
                        isShowingAlert = true
                        alertTitle = "There was an error"
                        alertMessage = "Failed to create task note. Please try again."
                        print(error)
                    }
                } label: {
                    Label(
                        task.hasNote ? "Open Obsidian note" : "Create Obsidian note",
                        systemImage: SFSymbols.obsidian.rawValue
                    )
                    .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(asset: TaskchampAsset.Assets.accentColor))
                Spacer()
                Menu {
                    Button(role: .destructive) {
                        do {
                            try DBService.shared.updatePendingTasks([task.uuid], withStatus: .deleted)
                            NotificationService.shared.deleteReminderForTask(task: task)
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
