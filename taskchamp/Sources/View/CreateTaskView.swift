import SwiftUI
import taskchampShared

// swiftlint:disable:next type_body_length
public struct CreateTaskView: View, UseKeyboardToolbar {
    @Environment(\.dismiss) var dismiss
    @Environment(StoreKitManager.self) var storeKit: StoreKitManager
    @Environment(GlobalState.self) var globalState: GlobalState

    @State private var nlpInput = ""
    @State private var nlpPlaceholder =
        "New Task due:tomorrow at 1pm project:my-project prio:M +my-tag"
    @State private var showNlpInfoPopover = false

    @State private var project = ""
    @State private var tags: [TCTag] = []
    @State private var description = ""
    @State private var status: TCTask.Status = .pending
    @State private var priority: TCTask.Priority = .none

    @State private var didSetDate = false
    @State private var didSetTime = false
    @State private var isDateShowing = false
    @State private var isTimeShowing = false

    @State private var due: Date = .init()
    @State private var time: Date = .init()

    @State private var showPaywall = false
    @State private var showTagPopover = false
    @State private var showLocationPicker = false
    @State private var locationReminder: TCLocationReminder?
    @State private var criticalAlert: TCCriticalAlert?
    @State private var isShowingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    @FocusState private var isFocused: Bool
    @FocusState private var focusedField: FormField?
    enum FormField {
        case nlp
        case description
        case project
    }

    func calculateNextField() {
        switch focusedField {
        case .nlp:
            focusedField = .description
        case .description:
            focusedField = .project
        case .project:
            focusedField = .project
        default:
            focusedField = nil
        }
    }

    func calculatePreviousField() {
        switch focusedField {
        case .nlp:
            focusedField = .nlp
        case .description:
            focusedField = .nlp
        case .project:
            focusedField = .description
        default:
            focusedField = nil
        }
    }

    func onDismissKeyboard() {
        focusedField = nil
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $nlpInput)
                        .font(.system(.body, design: .monospaced))
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .nlp)
                        .onChange(of: nlpInput) { _, input in
                            let nlpTask = NLPService.shared.createTask(from: input)
                            self.description = nlpTask.description
                            self.project = nlpTask.project ?? ""
                            self.priority = nlpTask.priority ?? .none
                            self.tags = nlpTask.tags ?? []
                            if let due = nlpTask.due {
                                didSetDate = true
                                didSetTime = true
                                let calendar = Calendar.current
                                let dateComponents = calendar.dateComponents([.year, .month, .day], from: due)
                                let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: due)
                                self.due = calendar.date(from: dateComponents) ?? .init()
                                time = calendar.date(from: timeComponents) ?? .init()
                                isTimeShowing = false
                            } else {
                                didSetDate = false
                                didSetTime = false
                                isDateShowing = false
                                isTimeShowing = false
                                due = .init()
                                time = .init()
                            }
                        }
                        .onFirstAppear {
                            focusedField = .nlp
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
                            ScrollView {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(
                                        "Create a task via a command line input. The format is as follows:"
                                    )
                                    .padding(.top)
                                    Text(nlpPlaceholder)
                                        .font(.system(.body, design: .monospaced))
                                    Text(
                                        // swiftlint:disable:next line_length
                                        "Manually updating the fields will override the values from the command line input."
                                    )
                                    .bold()
                                    .padding(.bottom)
                                }
                            }
                            .textCase(nil)
                            .frame(minHeight: 150)
                            .padding()
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                }
                Section {
                    TextEditor(text: $description)
                        .focused($focusedField, equals: .description)
                        .bold()
                    TextField("Project", text: $project)
                        .focused($focusedField, equals: .project)
                } header: {
                    Text("Description")
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
                    AddTagButton(tags: $tags) {
                        showTagPopover = true
                    }
                }
                CriticalAlertSettingsView(
                    criticalAlert: $criticalAlert,
                    hasDueDate: $didSetDate
                )
                Section {
                    LocationReminderButton(locationReminder: $locationReminder) {
                        showLocationPicker = true
                    }
                } header: {
                    Text("Location Reminder")
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

                        if !storeKit.hasPremiumAccess() && !tags.isEmpty {
                            showPaywall = true
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
                            due: finalDate,
                            tags: tags.isEmpty ? nil : tags,
                            locationReminder: locationReminder,
                            criticalAlert: criticalAlert
                        )

                        do {
                            globalState.isSyncingTasks = true
                            try TaskchampionService.shared.createTask(task) {
                                globalState.isSyncingTasks = false
                            }
                            NotificationService.shared.requestAuthorization()
                            NotificationService.shared.createReminderForTask(task: task)
                            if task.hasLocationReminder {
                                LocationService.shared.startMonitoringRegion(for: task)
                            }
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
                    KeyboardToolbarView(
                        onPrevious: {
                            calculatePreviousField()
                        },
                        onNext: {
                            calculateNextField()
                        },
                        onDismiss: {
                            onDismissKeyboard()
                        },
                        skipNextAndPrevious: { return focusedField == .nlp }
                        // swiftlint:disable:next multiple_closures_with_trailing_closure
                    ) {
                        if focusedField == .nlp {
                            AutocompleteBarView(
                                text: $nlpInput,
                                surface: .creation
                            )
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
            .navigationDestination(isPresented: $showPaywall) {
                TCPaywall()
            }
            .navigationDestination(isPresented: $showTagPopover) {
                AddTagView(selectedTags: $tags)
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(locationReminder: $locationReminder)
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
