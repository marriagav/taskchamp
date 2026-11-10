import Foundation
import taskchampShared
import XCTest

final class TCNotificationActionTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        // swiftlint:disable:next force_unwrapping
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        // swiftlint:disable:next force_unwrapping
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func task(status: TCTask.Status = .pending, due: Date? = nil) -> TCTask {
        TCTask(uuid: "8f14e45f-ceea-467a-9575-4f1a2b3c4d5e", description: "Water plants", status: status, due: due)
    }

    // MARK: - Registration

    func test_actionIdentifiers_areUnique() {
        let ids = TCNotificationAction.allCases.map(\.rawValue)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func test_actions_inMenuOrder() {
        XCTAssertEqual(
            TCNotificationAction.allCases,
            [.complete, .remindInOneHour, .remindTomorrow, .postponeOneHour, .postponeTomorrow]
        )
    }

    func test_kinds() {
        XCTAssertEqual(TCNotificationAction.complete.kind, .complete)
        XCTAssertEqual(TCNotificationAction.remindInOneHour.kind, .remind)
        XCTAssertEqual(TCNotificationAction.remindTomorrow.kind, .remind)
        XCTAssertEqual(TCNotificationAction.postponeOneHour.kind, .postpone)
        XCTAssertEqual(TCNotificationAction.postponeTomorrow.kind, .postpone)
    }

    // MARK: - Remind me

    func test_remindInOneHour_isOneHourFromNow() {
        let now = date(2026, 3, 2, 9, 30)
        XCTAssertEqual(
            TCNotificationAction.remindInOneHour.remindDate(now: now, calendar: calendar),
            date(2026, 3, 2, 10, 30)
        )
    }

    func test_remindTomorrow_isSameTimeTomorrow() {
        let now = date(2026, 3, 2, 9, 30)
        XCTAssertEqual(
            TCNotificationAction.remindTomorrow.remindDate(now: now, calendar: calendar),
            date(2026, 3, 3, 9, 30)
        )
    }

    func test_remindTomorrow_keepsWallClockTimeAcrossDST() {
        // US DST starts 2026-03-08; a 24-hour shift would land on 10:30.
        let now = date(2026, 3, 7, 9, 30)
        XCTAssertEqual(
            TCNotificationAction.remindTomorrow.remindDate(now: now, calendar: calendar),
            date(2026, 3, 8, 9, 30)
        )
    }

    func test_remindDate_isNilForOtherKinds() {
        let now = date(2026, 3, 2, 9)
        XCTAssertNil(TCNotificationAction.complete.remindDate(now: now, calendar: calendar))
        XCTAssertNil(TCNotificationAction.postponeOneHour.remindDate(now: now, calendar: calendar))
    }

    // MARK: - Postpone

    func test_postponeOneHour_countsFromDueDate() {
        let due = date(2026, 3, 2, 9)
        let now = date(2026, 3, 2, 11)
        XCTAssertEqual(
            TCNotificationAction.postponeOneHour.postponedDueDate(from: due, now: now, calendar: calendar),
            date(2026, 3, 2, 10)
        )
    }

    func test_postponeTomorrow_isSameTimeNextDay() {
        let due = date(2026, 3, 2, 9)
        XCTAssertEqual(
            TCNotificationAction.postponeTomorrow.postponedDueDate(from: due, now: due, calendar: calendar),
            date(2026, 3, 3, 9)
        )
    }

    func test_postpone_withoutDueDate_countsFromNow() {
        let now = date(2026, 3, 2, 14)
        XCTAssertEqual(
            TCNotificationAction.postponeOneHour.postponedDueDate(from: nil, now: now, calendar: calendar),
            date(2026, 3, 2, 15)
        )
    }

    func test_postponedDueDate_isNilForOtherKinds() {
        let now = date(2026, 3, 2, 9)
        XCTAssertNil(TCNotificationAction.complete.postponedDueDate(from: now, now: now, calendar: calendar))
        XCTAssertNil(TCNotificationAction.remindTomorrow.postponedDueDate(from: now, now: now, calendar: calendar))
    }

    // MARK: - apply(to:)

    func test_apply_complete_marksPendingTaskCompleted() {
        let result = TCNotificationAction.complete.apply(to: task(), now: Date(), calendar: calendar)
        XCTAssertEqual(result?.status, .completed)
    }

    func test_apply_complete_doesNotReopenCompletedTask() {
        let completed = task(status: .completed)
        XCTAssertNil(TCNotificationAction.complete.apply(to: completed, now: Date(), calendar: calendar))
    }

    func test_apply_doesNotChangeDeletedTask() {
        let deleted = task(status: .deleted, due: date(2026, 3, 2, 9))
        for action in TCNotificationAction.allCases {
            XCTAssertNil(action.apply(to: deleted, now: Date(), calendar: calendar), "\(action)")
        }
    }

    func test_apply_postpone_movesDueDateAndKeepsStatus() {
        let original = task(due: date(2026, 3, 2, 9))
        let result = TCNotificationAction.postponeTomorrow.apply(to: original, now: Date(), calendar: calendar)
        XCTAssertEqual(result?.due, date(2026, 3, 3, 9))
        XCTAssertEqual(result?.status, .pending)
        XCTAssertEqual(result?.uuid, original.uuid)
        XCTAssertEqual(result?.description, original.description)
    }

    func test_apply_remind_neverChangesTask() {
        let original = task(due: date(2026, 3, 2, 9))
        XCTAssertNil(TCNotificationAction.remindInOneHour.apply(to: original, now: Date(), calendar: calendar))
        XCTAssertNil(TCNotificationAction.remindTomorrow.apply(to: original, now: Date(), calendar: calendar))
    }
}
