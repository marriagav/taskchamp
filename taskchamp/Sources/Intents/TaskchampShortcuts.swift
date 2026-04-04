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
    }
}
