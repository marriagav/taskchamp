import SwiftUI
import taskchampShared

public struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var suggestOnlyActiveProjects: Bool = UserDefaultsManager.standard
        .getValue(forKey: .suggestOnlyActiveProjects) ?? true

    @AppStorage(TCUserDefaults.taskCellLineLimit.rawValue) private var taskCellLineLimit: Int = 2
    @AppStorage(TCUserDefaults.dueLookaheadDays.rawValue) private var dueLookaheadDays: Int = 7

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
