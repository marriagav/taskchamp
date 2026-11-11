import Foundation
import taskchampShared
import Testing

/// Tests for the command line input on the create task screen, including the prefill
/// text that the widget's + button and the "Open Quick Add" shortcut put in front of the task name.
@MainActor
@Suite("Command line task input")
struct NLPServiceTests {
    /// An input and the fields it should produce. Due dates are checked separately because they're relative.
    struct ParseCase: CustomTestStringConvertible, Sendable {
        let input: String
        let description: String
        var tags: [String] = []
        var project: String?
        var priority: String?

        var testDescription: String { "\"\(input)\"" }
    }

    static let parseCases: [ParseCase] = [
        // Plain description
        ParseCase(input: "Buy milk", description: "Buy milk"),
        // Keywords after the description
        ParseCase(input: "Buy milk +errand", description: "Buy milk", tags: ["errand"]),
        ParseCase(input: "Buy milk project:home", description: "Buy milk", project: "home"),
        ParseCase(input: "Buy milk prio:H", description: "Buy milk", priority: "H"),
        // Keywords before the description, as produced by a widget or shortcut prefill
        ParseCase(input: "+chore Clean kitchen", description: "Clean kitchen", tags: ["chore"]),
        ParseCase(input: "project:home Clean kitchen", description: "Clean kitchen", project: "home"),
        ParseCase(input: "prio:H Fix bug", description: "Fix bug", priority: "H"),
        ParseCase(
            input: "+chore project:home Clean kitchen",
            description: "Clean kitchen",
            tags: ["chore"],
            project: "home"
        ),
        // The prefill alone, before the user types anything
        ParseCase(input: "+test ", description: "", tags: ["test"]),
        // Keywords in the middle
        ParseCase(input: "Clean +chore kitchen", description: "Clean kitchen", tags: ["chore"]),
        // Multiple and duplicate tags
        ParseCase(input: "Call mom +family +phone", description: "Call mom", tags: ["family", "phone"]),
        ParseCase(input: "Buy milk +errand +errand", description: "Buy milk", tags: ["errand"]),
        // Everything at once, matching the placeholder shown in the app
        ParseCase(
            input: "New Task project:my-project prio:M +my-tag",
            description: "New Task",
            tags: ["my-tag"],
            project: "my-project",
            priority: "M"
        ),
        // A lone "+" isn't a tag
        ParseCase(input: "Buy milk + eggs", description: "Buy milk eggs")
    ]

    @Test("Parses description, tags, project and priority", arguments: parseCases)
    func parsesFields(_ testCase: ParseCase) {
        let task = NLPService.shared.createTask(from: testCase.input)

        #expect(task.description == testCase.description)
        #expect((task.tags ?? []).map(\.name) == testCase.tags)
        #expect(task.project == testCase.project)
        #expect(task.priority?.rawValue == testCase.priority)
    }

    // MARK: - Due dates

    private let calendar = Calendar.current

    private func day(offset: Int) -> Date {
        let today = calendar.startOfDay(for: .now)
        return calendar.date(byAdding: .day, value: offset, to: today) ?? today
    }

    /// Midnight dates can have the user's default due time applied, so only the day is compared.
    private func expectDue(_ input: String, onDayOffset offset: Int, description: String) throws {
        let task = NLPService.shared.createTask(from: input)
        let due = try #require(task.due, "Expected a due date for \"\(input)\"")
        #expect(calendar.isDate(due, inSameDayAs: day(offset: offset)), "Wrong day for \"\(input)\"")
        #expect(task.description == description)
    }

    @Test func dueTodayAfterDescription() throws {
        try expectDue("Buy milk due:today", onDayOffset: 0, description: "Buy milk")
    }

    @Test func dueTodayBeforeDescription() throws {
        try expectDue("due:today Buy milk", onDayOffset: 0, description: "Buy milk")
    }

    @Test func widgetPrefillWithTagAndDue() throws {
        let task = NLPService.shared.createTask(from: "+test due:today Buy milk")
        let due = try #require(task.due)
        #expect(calendar.isDate(due, inSameDayAs: day(offset: 0)))
        #expect(task.description == "Buy milk")
        #expect((task.tags ?? []).map(\.name) == ["test"])
    }

    @Test func widgetPrefillAloneHasNoDescription() throws {
        try expectDue("+test due:today ", onDayOffset: 0, description: "")
    }

    @Test func dueInDaysBeforeDescription() throws {
        try expectDue("due:in 2 days Water plants", onDayOffset: 2, description: "Water plants")
    }

    @Test func dueFollowedByWordsThatBreakParsing() throws {
        // "today 3 apples" doesn't parse as a whole, so the longest prefix that does ("today") is used.
        try expectDue("due:today 3 apples", onDayOffset: 0, description: "3 apples")
    }

    @Test func multiWordDueWithTimeKeepsTime() throws {
        for input in ["Buy milk due:tomorrow at 1pm", "due:tomorrow at 1pm Buy milk"] {
            let task = NLPService.shared.createTask(from: input)
            let due = try #require(task.due, "Expected a due date for \"\(input)\"")
            #expect(calendar.isDate(due, inSameDayAs: day(offset: 1)), "Wrong day for \"\(input)\"")
            #expect(calendar.component(.hour, from: due) == 13, "Wrong hour for \"\(input)\"")
            #expect(task.description == "Buy milk")
        }
    }

    @Test func multiWordDueFollowedByKeyword() throws {
        let task = NLPService.shared.createTask(from: "due:tomorrow at 1pm Call mom +work")
        let due = try #require(task.due)
        #expect(calendar.component(.hour, from: due) == 13)
        #expect(task.description == "Call mom")
        #expect((task.tags ?? []).map(\.name) == ["work"])
    }

    @Test func dueNextWeekIsParsed() {
        let task = NLPService.shared.createTask(from: "Pay rent due:next week")
        #expect(task.due != nil)
        #expect(task.description == "Pay rent")
    }

    @Test func invalidDueKeepsDescription() {
        let task = NLPService.shared.createTask(from: "due:asdf Buy milk")
        #expect(task.due == nil)
        #expect(task.description == "Buy milk")
    }

    // MARK: - Widget prefill link

    /// Mirrors how the app reads the `content` query when it opens the new task link.
    private func content(of url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "content" })?.value
    }

    @Test(
        "Prefill survives the new task link",
        arguments: ["+chore", "+chore project:home due:tomorrow", "Buy milk & eggs +errand", "100% done?"]
    )
    func prefillRoundTrips(_ prefill: String) {
        let url = TCTask.newTaskUrl(prefilledWith: prefill)
        #expect(url.scheme == "taskchamp")
        #expect(url.host == "task")
        #expect(url.pathComponents == ["/", "new"])
        #expect(content(of: url) == prefill)
    }

    @Test("Empty prefill uses the plain new task link", arguments: ["", "   ", "\n"])
    func emptyPrefillUsesPlainLink(_ prefill: String) {
        #expect(TCTask.newTaskUrl(prefilledWith: prefill) == TCTask.newTaskUrl)
    }
}
