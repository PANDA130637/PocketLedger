import XCTest
import CoreData
@testable import PocketLedger

final class LedgerTests: XCTestCase {
    func testValidMoneyIsExact() throws {
        XCTAssertEqual(try Money.parse("0.01"), 1)
        XCTAssertEqual(try Money.parse("12.3"), 1230)
        XCTAssertEqual(try Money.parse(" 38.50 "), 3850)
        XCTAssertEqual(try Money.parse("999999999.99"), Money.maximumCents)
        XCTAssertEqual(try Money.parse("0001.20"), 120)
    }

    func testInvalidMoneyIsRejected() {
        for input in ["", "0", "0.00", "-1", "+1", "1.234", "1.", ".5", "1,23", "NaN", "1e3", "abc", "1 2", "1000000000", "9223372036854775807", "9999999999999999999999"] {
            XCTAssertThrowsError(try Money.parse(input), input)
        }
    }

    func testInsertionValidationAndDeletion() throws {
        let persistence = try PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        try context.performAndWait {
            let entry = try LedgerStore.add(amount: "12.34", kind: .expense, category: .food,
                                            date: Date(), note: " 午餐 ", in: context)
            XCTAssertEqual(entry.amountCents, 1234)
            XCTAssertEqual(entry.note, "午餐")
            XCTAssertFalse(entry.objectID.isTemporaryID)
            context.reset()
            let saved = try XCTUnwrap(context.fetch(LedgerEntry.allEntriesRequest()).first)
            XCTAssertEqual(saved.amountCents, 1234)
            XCTAssertThrowsError(try LedgerStore.add(amount: "10", kind: .income, category: .food,
                                                     date: Date(), note: "", in: context))
            XCTAssertThrowsError(try LedgerStore.add(amount: "10", kind: .expense, category: .food,
                                                     date: Date(), note: String(repeating: "字", count: 101), in: context))
            XCTAssertThrowsError(try LedgerStore.add(amount: "0", kind: .expense, category: .food,
                                                     date: Date(), note: "", in: context))
            XCTAssertEqual(try context.count(for: LedgerEntry.allEntriesRequest()), 1)
            try LedgerStore.delete([saved], in: context)
            XCTAssertEqual(try context.count(for: LedgerEntry.allEntriesRequest()), 0)
        }
    }

    func testMonthBoundariesAndCategoryTotals() throws {
        let persistence = try PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 1)))
        let end = try XCTUnwrap(calendar.date(byAdding: .month, value: 1, to: start))
        try context.performAndWait {
            _ = try LedgerStore.add(amount: "1000", kind: .income, category: .salary, date: start, note: "", in: context)
            let food = try LedgerStore.add(amount: "30.01", kind: .expense, category: .food, date: start, note: "", in: context)
            _ = try LedgerStore.add(amount: "9.99", kind: .expense, category: .food, date: end.addingTimeInterval(-1), note: "", in: context)
            _ = try LedgerStore.add(amount: "6", kind: .expense, category: .transport, date: start, note: "", in: context)
            _ = try LedgerStore.add(amount: "999", kind: .expense, category: .food, date: start.addingTimeInterval(-1), note: "", in: context)
            _ = try LedgerStore.add(amount: "888", kind: .expense, category: .food, date: end, note: "", in: context)
            let summary = try MonthlySummary.fetch(in: context, month: start, calendar: calendar)
            XCTAssertEqual(summary.income, 100000)
            XCTAssertEqual(summary.expense, 4600)
            XCTAssertEqual(summary.balance, 95400)
            XCTAssertEqual(summary.categories.map(\.category), [.food, .transport])
            XCTAssertEqual(summary.categories.map(\.cents), [4000, 600])
            try LedgerStore.delete([food], in: context)
            XCTAssertEqual(try MonthlySummary.fetch(in: context, month: start, calendar: calendar).expense, 1599)
        }
    }

    func testEmptyMonth() throws {
        let persistence = try PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        try context.performAndWait {
            XCTAssertEqual(try MonthlySummary.fetch(in: context, month: Date()), MonthlySummary())
        }
    }
}
