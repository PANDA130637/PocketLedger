import CoreData
import Combine

struct CategoryTotal: Identifiable, Equatable {
    let category: LedgerCategory
    let cents: Int64
    var id: String { category.rawValue }
}

struct MonthlySummary: Equatable {
    var income: Int64 = 0
    var expense: Int64 = 0
    var categories: [CategoryTotal] = []
    var balance: Int64 { income - expense }

    static func fetch(in context: NSManagedObjectContext, month: Date,
                      calendar: Calendar = .current) throws -> MonthlySummary {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return .init() }
        let request = LedgerEntry.allEntriesRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                        interval.start as NSDate, interval.end as NSDate)
        request.sortDescriptors = []
        let entries = try context.fetch(request)
        var result = MonthlySummary()
        var grouped: [LedgerCategory: Int64] = [:]
        for entry in entries {
            if entry.kind == .income {
                result.income += entry.amountCents
            } else {
                result.expense += entry.amountCents
                grouped[entry.category, default: 0] += entry.amountCents
            }
        }
        result.categories = grouped.map { CategoryTotal(category: $0.key, cents: $0.value) }
            .sorted { $0.cents == $1.cents ? $0.id < $1.id : $0.cents > $1.cents }
        return result
    }
}

// Owned by the statistics screen. Aggregation is outside View.body and runs only
// on saves or calendar-month/time-zone changes, using the main-queue context.
final class StatisticsModel: ObservableObject {
    @Published private(set) var summary = MonthlySummary()
    @Published private(set) var month = Date()
    @Published private(set) var errorMessage: String?
    private let context: NSManagedObjectContext
    private var interval: DateInterval?
    private var observation: AnyCancellable?

    init(context: NSManagedObjectContext) {
        self.context = context
        reload()
        observation = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.reload() }
    }

    func refreshMonthIfNeeded(now: Date = Date()) {
        if interval != Calendar.current.dateInterval(of: .month, for: now) {
            reload(now: now)
        }
    }

    func reload(now: Date = Date()) {
        month = now
        interval = Calendar.current.dateInterval(of: .month, for: now)
        do {
            let updated = try MonthlySummary.fetch(in: context, month: now)
            if summary != updated { summary = updated }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
