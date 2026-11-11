import Foundation
import taskchampShared
import Testing

/// Tests for filter queries such as the app icon badge query, focused on the status virtual tags.
@MainActor
@Suite("Filter queries")
struct FilterExpressionTests {
    /// Builds a task the way the database loader would, including the synthetic DUE tag when it's due.
    private func task(_ status: TCTask.Status, due: Bool = false, tags: [String] = []) -> TCTask {
        var allTags = tags.map { TCTag(name: $0) }
        if due {
            allTags.append(TCSyntheticTag.due.toTCTag())
        }
        return TCTask(
            uuid: UUID().uuidString,
            description: "Task",
            status: status,
            due: due ? .now : nil,
            tags: allTags.isEmpty ? nil : allTags
        )
    }

    private func matches(_ query: String, _ task: TCTask) throws -> Bool {
        let expression = try #require(FilterParser.parse(query), "Query \"\(query)\" should parse")
        return expression.matches(task)
    }

    @Test func pendingMatchesOnlyPendingTasks() throws {
        #expect(try matches("+PENDING", task(.pending)))
        #expect(try !matches("+PENDING", task(.completed)))
        #expect(try !matches("+PENDING", task(.deleted)))
    }

    @Test func completedAndDeletedMatchTheirStatus() throws {
        #expect(try matches("+COMPLETED", task(.completed)))
        #expect(try !matches("+COMPLETED", task(.pending)))
        #expect(try matches("+DELETED", task(.deleted)))
        #expect(try !matches("+DELETED", task(.pending)))
    }

    @Test func excludingAStatus() throws {
        #expect(try matches("-COMPLETED", task(.pending)))
        #expect(try !matches("-COMPLETED", task(.completed)))
    }

    @Test("Default badge query counts pending tasks that are due")
    func defaultBadgeQuery() throws {
        let query = BadgeService.defaultQuery
        #expect(try matches(query, task(.pending, due: true)))
        #expect(try !matches(query, task(.pending)))
        // Without +PENDING, finished tasks with a due date would be counted too.
        #expect(try !matches(query, task(.completed, due: true)))
        #expect(try !matches(query, task(.deleted, due: true)))
    }

    @Test func statusTagsCombineWithRegularTags() throws {
        #expect(try matches("+PENDING +work", task(.pending, tags: ["work"])))
        #expect(try !matches("+PENDING +work", task(.pending, tags: ["home"])))
        #expect(try matches("+PENDING (+work or +home)", task(.pending, tags: ["home"])))
    }

    @Test("Badge queries without any filter terms are invalid", arguments: ["", "   ", "hello world"])
    func invalidBadgeQueries(_ query: String) {
        #expect(!BadgeService.isValidQuery(query))
    }

    @Test("Badge queries with filter terms are valid", arguments: ["+PENDING +DUE", "project:home", "prio:H"])
    func validBadgeQueries(_ query: String) {
        #expect(BadgeService.isValidQuery(query))
    }
}
