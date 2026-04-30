import AppIntents

struct TaskchampShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenFilterIntent(),
            phrases: [
                "Open \(\.$filter) in \(.applicationName)",
                "Show \(\.$filter) in \(.applicationName)"
            ],
            shortTitle: "Open Filter",
            systemImageName: "line.3.horizontal.decrease.circle"
        )
        AppShortcut(
            intent: OpenNewTaskIntent(),
            phrases: [
                "Quick add in \(.applicationName)",
                "New task in \(.applicationName)",
                "Add task in \(.applicationName)"
            ],
            shortTitle: "Open Quick Add",
            systemImageName: "plus.circle.fill"
        )
    }
}
