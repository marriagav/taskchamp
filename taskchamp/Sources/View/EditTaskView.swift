import SwiftUI
import taskchampShared

public struct EditTaskView: View {
    @State var task: TCTask

    @Environment(\.dismiss) var dismiss

    @State var project = ""
    @State var description = ""
    @State var status: TCTask.Status = .pending
    @State var priority: TCTask.Priority = .none

    @State var didSetDate = false
    @State var didSetTime = false
    @State var isDateShowing = false
    @State var isTimeShowing = false

    @State var due: Date = .init()
    @State var time: Date = .init()

    @State var isShowingAlert = false
    @State var isShowingObsidianSettings = false
    @State var alertTitle = ""
    @State var alertMessage = ""

    @FocusState var isFocused: Bool

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
                    handleTaskActionTap()
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
                    updateTask()
                }
                .disabled(!didChange)
                .bold()
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    handleObsidianTap()
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
                        deleteTask()
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
        .sheet(isPresented: $isShowingObsidianSettings) {
            ObsidianSettingsView()
        }
        .navigationTitle(description)
    }
}
