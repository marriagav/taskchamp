import SwiftUI
import taskchampShared

public struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var suggestOnlyActiveProjects: Bool = UserDefaultsManager.standard
        .getValue(forKey: .suggestOnlyActiveProjects) ?? true

    @AppStorage(TCUserDefaults.taskCellLineLimit.rawValue) private var taskCellLineLimit: Int = 2
    @AppStorage(TCUserDefaults.dueLookaheadDays.rawValue) private var dueLookaheadDays: Int = 7
    @AppStorage(TCUserDefaults.hasDefaultDueTime.rawValue) private var hasDefaultDueTime: Bool = false
    @AppStorage(TCUserDefaults.defaultDueTimeMinutes.rawValue) private var defaultDueTimeMinutes: Int = 9 * 60

    // Badge settings live in the app group so the widget extension can refresh the badge.
    @AppStorage(
        TCUserDefaults.badgeCountEnabled.rawValue,
        store: UserDefaults(suiteName: UserDefaultsManager.suiteName)
    ) private var badgeCountEnabled: Bool = false
    @AppStorage(
        TCUserDefaults.badgeCountQuery.rawValue,
        store: UserDefaults(suiteName: UserDefaultsManager.suiteName)
    ) private var badgeCountQuery: String = BadgeService.defaultQuery
    @State private var badgeMatchCount: Int?

    private var badgeFooter: String {
        guard BadgeService.isValidQuery(badgeCountQuery) else {
            return "Enter a filter query, for example \(BadgeService.defaultQuery)."
        }
        let description = "Shows how many tasks match this query on the app icon. " +
            "Uses the same syntax as filters, plus +PENDING, +COMPLETED and +DELETED."
        guard let badgeMatchCount else { return description }
        return description + " \(badgeMatchCount) task\(badgeMatchCount == 1 ? "" : "s") match right now."
    }

    private func refreshBadge() {
        badgeMatchCount = BadgeService.count(for: badgeCountQuery)
        Task { await BadgeService.refresh() }
    }

    private var defaultDueTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: defaultDueTimeMinutes / 60,
                    minute: defaultDueTimeMinutes % 60,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                defaultDueTimeMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
        )
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Max lines per task", selection: $taskCellLineLimit) {
                        ForEach(1...5, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                } header: {
                    Text("Task List")
                } footer: {
                    Text("Sets how many lines a task description can wrap to in the main task list.")
                }
                Section {
                    Stepper(value: $dueLookaheadDays, in: 1...365) {
                        HStack {
                            Text("+DUE look-ahead")
                            Spacer()
                            Text("\(dueLookaheadDays) day\(dueLookaheadDays == 1 ? "" : "s")")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Filters")
                } footer: {
                    Text(
                        "Tasks due within this many days from now will match the +DUE synthetic tag."
                    )
                }
                Section {
                    Toggle("Show badge count", isOn: $badgeCountEnabled)
                        .onChange(of: badgeCountEnabled) { _, isEnabled in
                            if isEnabled {
                                // The badge needs notification permission; this is a no-op if already granted.
                                NotificationService.shared.requestAuthorization()
                            }
                            refreshBadge()
                        }
                    if badgeCountEnabled {
                        TextField("Query", text: $badgeCountQuery, prompt: Text(BadgeService.defaultQuery))
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: badgeCountQuery) { _, _ in
                                refreshBadge()
                            }
                    }
                } header: {
                    Text("App Icon Badge")
                } footer: {
                    if badgeCountEnabled {
                        Text(badgeFooter)
                    }
                }
                .onAppear {
                    badgeMatchCount = BadgeService.count(for: badgeCountQuery)
                }
                Section {
                    Toggle("Use default due time", isOn: $hasDefaultDueTime)
                    if hasDefaultDueTime {
                        DatePicker(
                            "Default time",
                            selection: defaultDueTimeBinding,
                            displayedComponents: [.hourAndMinute]
                        )
                    }
                } header: {
                    Text("Due Date")
                } footer: {
                    Text(
                        "When on, tasks with a due date but no due time will use this time " +
                            "(e.g. due:today becomes today at the chosen time)."
                    )
                }
                Section {
                    Toggle("Suggest only active projects", isOn: $suggestOnlyActiveProjects)
                        .onChange(of: suggestOnlyActiveProjects) { _, newValue in
                            UserDefaultsManager.standard.set(value: newValue, forKey: .suggestOnlyActiveProjects)
                            NLPService.shared.refreshProjectsCache()
                        }
                } header: {
                    Text("Project Suggestions")
                } footer: {
                    Text(
                        "When on, project autocomplete only suggests projects from pending tasks. " +
                            "When off, it suggests every project that has ever been used."
                    )
                }
            }
            .navigationTitle("App Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}
