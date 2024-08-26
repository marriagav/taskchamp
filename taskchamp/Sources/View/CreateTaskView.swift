import SwiftUI
import taskchampShared

public struct CreateTaskView: View {
    @Environment(\.dismiss) var dismiss

    @State private var nlpInput = ""
    @State private var nlpPlaceholder = "New Task@tomorrow at 1pm@ project:my-project prio:M"
    @State private var showNlpInfoPopover = false

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

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $nlpInput)
                        .font(.system(.body, design: .monospaced))
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                        .onChange(of: nlpInput) { _, input in
                            let nlpTask = try? NLPService.shared.createTask(from: input)
                            self.description = nlpTask?.description ?? ""
                            self.project = nlpTask?.project ?? ""
                            self.priority = nlpTask?.priority ?? .none
                            if let due = nlpTask?.due {
                                didSetDate = true
                                didSetTime = true
                                let calendar = Calendar.current
                                let dateComponents = calendar.dateComponents([.year, .month, .day], from: due)
                                let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: due)
                                self.due = calendar.date(from: dateComponents) ?? .init()
                                time = calendar.date(from: timeComponents) ?? .init()
                                isTimeShowing = false
                            }
                        }
                } header: {
                    HStack {
                        Text("Command Line Input")
                        Button {
                            showNlpInfoPopover.toggle()
                        } label: {
                            Image(systemName: SFSymbols.questionmarkCircle.rawValue)
                        }
                        .popover(isPresented: $showNlpInfoPopover, attachmentAnchor: .point(.bottom)) {
                            VStack(alignment: .leading, spacing: 10) {
                                Spacer()
                                Text(
                                    "Create a task via a command line input. The format is as follows:"
                                )
                                .padding(.top)
                                Text("New Task@tomorrow at 1pm@ project:my-project prio:M")
                                    .font(.system(.body, design: .monospaced))
                                Text(
                                    "Manually updating the fields will override the values from the command line input."
                                )
                                .bold()
                                .padding(.bottom)
                                Spacer()
                            }
                            .textCase(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                }
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

                        let task = TCTask(
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
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
