import SwiftUI
import taskchampShared

struct ShareComposeView: View {
    var sharedText: String?
    var onComplete: () -> Void
    var onCancel: () -> Void

    @State private var nlpInput = ""
    @State private var description = ""
    @State private var project = ""
    @State private var tags: [TCTag] = []
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
    @State private var showDismissConfirmation = false
    @State private var showTagView = false
    @State private var showNlpInfoPopover = false
    @State private var isReady = false

    @FocusState private var focusedField: FormField?
    enum FormField {
        case nlp
        case description
        case project
    }

    private var hasUnsavedContent: Bool {
        !nlpInput.isEmpty || !description.isEmpty
    }

    private func calculateNextField() {
        switch focusedField {
        case .nlp: focusedField = .description
        case .description: focusedField = .project
        case .project: focusedField = .project
        default: focusedField = nil
        }
    }

    private func calculatePreviousField() {
        switch focusedField {
        case .nlp: focusedField = .nlp
        case .description: focusedField = .nlp
        case .project: focusedField = .description
        default: focusedField = nil
        }
    }

    var body: some View {
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
                                let dateComponents = calendar.dateComponents(
                                    [.year, .month, .day], from: due
                                )
                                let timeComponents = calendar.dateComponents(
                                    [.hour, .minute, .second], from: due
                                )
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
                } header: {
                    HStack {
                        Text("Command Line Input")
                        Button {
                            showNlpInfoPopover.toggle()
                        } label: {
                            Image(systemName: SFSymbols.questionmarkCircle.rawValue)
                        }
                        .popover(
                            isPresented: $showNlpInfoPopover,
                            attachmentAnchor: .point(.bottom)
                        ) {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(
                                        "Create a task via a command line input. The format is as follows:"
                                    )
                                    .padding(.top)
                                    Text(
                                        "New Task due:tomorrow at 1pm project:my-project prio:M +my-tag"
                                    )
                                    .font(.system(.body, design: .monospaced))
                                    Text(
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
                    ShareDateToggleButton(
                        isOnlyTime: false,
                        date: $due,
                        isSet: $didSetDate,
                        isDateShowing: $isDateShowing
                    )
                    ShareDateToggleButton(
                        isOnlyTime: true,
                        date: $time,
                        isSet: $didSetTime,
                        isDateShowing: $isTimeShowing
                    )
                }
                Section {
                    Picker(
                        "Priority",
                        systemImage: SFSymbols.exclamationmark.rawValue,
                        selection: $priority
                    ) {
                        Text(TCTask.Priority.none.rawValue.capitalized)
                            .tag(TCTask.Priority.none)
                        Divider()
                        ForEach(TCTask.Priority.allCases, id: \.self) { priority in
                            if priority != .none {
                                Text(priority.rawValue.capitalized)
                            }
                        }
                    }
                    ShareAddTagButton(tags: $tags) {
                        showTagView = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        createTask()
                    }
                    .bold()
                    .tint(.indigo)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedContent {
                            showDismissConfirmation = true
                        } else {
                            onCancel()
                        }
                    }
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        if focusedField != .nlp {
                            Button(action: calculatePreviousField) {
                                Label("Previous", systemImage: SFSymbols.chevronUp.rawValue)
                            }
                            Button(action: calculateNextField) {
                                Label("Next", systemImage: SFSymbols.chevronDown.rawValue)
                            }
                        }
                        Spacer()
                        if focusedField == .nlp {
                            ShareAutocompleteBar(text: $nlpInput)
                        }
                        Spacer()
                        Button(action: { focusedField = nil }) {
                            Label(
                                "Dismiss keyboard",
                                systemImage: SFSymbols.checkmark.rawValue
                            )
                        }
                    }
                }
            }
            .onChange(of: didSetTime) { _, newValue in
                if didSetTime {
                    didSetDate = true
                    isDateShowing = false
                    withAnimation {
                        isTimeShowing = newValue
                    }
                }
            }
            .onChange(of: didSetDate) { _, _ in
                if !didSetDate {
                    didSetTime = false
                    isTimeShowing = false
                } else if didSetDate, !didSetTime {
                    withAnimation {
                        isDateShowing = didSetDate
                    }
                }
            }
            .animation(.default, value: didSetDate)
            .animation(.default, value: didSetTime)
            .alert(isPresented: $isShowingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .confirmationDialog(
                "Are you sure? This will dismiss without creating the task",
                isPresented: $showDismissConfirmation,
                titleVisibility: .visible
            ) {
                Button("Dismiss task", role: .destructive) { onCancel() }
                Button("Cancel", role: .cancel) {}
            }
            .navigationDestination(isPresented: $showTagView) {
                ShareAddTagView(selectedTags: $tags)
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await initializeServices()
                if let sharedText {
                    nlpInput = sharedText + " "
                }
                focusedField = .nlp
            }
        }
    }

    private func initializeServices() async {
        do {
            let destinationPath = try FileService.shared.getDestinationPathForLocalReplica()
            try TaskchampionService.shared.setDbUrl(path: destinationPath)
            isReady = true
        } catch {
            alertTitle = "Setup Error"
            alertMessage = "Could not initialize task database."
            isShowingAlert = true
        }
    }

    private func createTask() {
        guard isReady else {
            alertTitle = "Not Ready"
            alertMessage = "Task database is still initializing. Please try again."
            isShowingAlert = true
            return
        }

        if description.isEmpty {
            alertTitle = "Missing field"
            alertMessage = "Please enter a task name"
            isShowingAlert = true
            return
        }

        let finalDate = mergeDateWithTime(
            date: didSetDate ? due : nil,
            time: didSetTime ? time : nil
        )

        let task = TCTask(
            uuid: UUID().uuidString,
            project: project.isEmpty ? nil : project,
            description: description,
            status: .pending,
            priority: priority == .none ? nil : priority,
            due: finalDate,
            tags: tags.isEmpty ? nil : tags
        )

        do {
            try TaskchampionService.shared.createTask(task)
            NotificationService.shared.requestAuthorization()
            NotificationService.shared.createReminderForTask(task: task)
            onComplete()
        } catch {
            alertTitle = "There was an error"
            alertMessage = "Task failed to create. Please try again."
            isShowingAlert = true
        }
    }

    private func mergeDateWithTime(date: Date?, time: Date?) -> Date? {
        guard let date else { return nil }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let time {
            let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
        }
        return Calendar.current.date(from: components)
    }
}

// MARK: - Date Toggle Button

private struct ShareDateToggleButton: View {
    var isOnlyTime: Bool
    @Binding var date: Date
    @Binding var isSet: Bool
    @Binding var isDateShowing: Bool

    var body: some View {
        Button(
            action: {
                if isSet {
                    withAnimation {
                        isDateShowing.toggle()
                    }
                }
            },
            label: {
                Toggle(isOn: $isSet) {
                    Label {
                        HStack {
                            Text(isOnlyTime ? "Time" : "Date")
                                .foregroundStyle(.primary)
                            if isSet {
                                Text(" \u{2022} ")
                                    .foregroundStyle(.tertiary)
                                Text(date, style: isOnlyTime ? .time : .date)
                                    .foregroundStyle(.tint)
                                    .font(.footnote)
                            }
                        }
                    } icon: {
                        Image(
                            systemName: isOnlyTime
                                ? SFSymbols.clockFill.rawValue
                                : SFSymbols.calendar.rawValue
                        )
                        .foregroundStyle(.tint)
                    }
                }
            }
        )
        .foregroundStyle(.primary)
        if isSet && isDateShowing {
            HStack {
                Spacer()
                if isOnlyTime {
                    DatePicker(
                        "Time",
                        selection: $date,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                } else {
                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }
                Spacer()
            }
            .listRowInsets(.init(top: 0, leading: 10, bottom: 0, trailing: 10))
        }
    }
}

// MARK: - Add Tag Button

private struct ShareAddTagButton: View {
    @Binding var tags: [TCTag]
    var action: () -> Void

    private var uniqueTags: [TCTag] {
        var seen = Set<String>()
        return tags.filter { tag in
            if seen.contains(tag.name) {
                return false
            } else {
                seen.insert(tag.name)
                return true
            }
        }
    }

    var body: some View {
        Button {
            action()
        } label: {
            if tags.isEmpty {
                Label("Tags", systemImage: SFSymbols.tag.rawValue)
                    .labelStyle(.titleAndIcon)
            } else {
                Label {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(uniqueTags, id: \.self) { tag in
                                Text(tag.name)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color.accentColor.opacity(0.2))
                                    )
                            }
                        }
                    }
                    .onTapGesture {
                        action()
                    }
                } icon: {
                    Image(systemName: SFSymbols.tag.rawValue)
                }
            }
        }
    }
}

// MARK: - Autocomplete Bar

private struct ShareAutocompleteBar: View {
    @Binding var text: String

    private var suggestions: [String] {
        NLPService.shared.autoCompleteSuggestions(for: text, surface: .creation)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        text = NLPService.shared.getAutoCompletedString(
                            for: text, suggestion: suggestion
                        )
                    } label: {
                        Text(suggestion)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.accentColor.opacity(0.2))
                            )
                    }
                }
            }
        }
    }
}
