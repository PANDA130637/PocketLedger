import CoreData

enum EntryKind: String, CaseIterable, Identifiable {
    case expense, income
    var id: String { rawValue }
    var title: String { self == .expense ? "支出" : "收入" }
    var categories: [LedgerCategory] {
        self == .expense
            ? [.food, .transport, .shopping, .housing, .entertainment, .other]
            : [.salary, .bonus, .other]
    }
}

enum LedgerCategory: String, CaseIterable, Identifiable {
    case food, transport, shopping, housing, entertainment, salary, bonus, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .food: return "餐饮"
        case .transport: return "交通"
        case .shopping: return "购物"
        case .housing: return "住房"
        case .entertainment: return "娱乐"
        case .salary: return "工资"
        case .bonus: return "奖金"
        case .other: return "其他"
        }
    }
    var symbol: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "tram.fill"
        case .shopping: return "bag.fill"
        case .housing: return "house.fill"
        case .entertainment: return "gamecontroller.fill"
        case .salary: return "briefcase.fill"
        case .bonus: return "gift.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }
}

@objc(LedgerEntry)
final class LedgerEntry: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var amountCents: Int64
    @NSManaged var kindRaw: String
    @NSManaged var categoryRaw: String
    @NSManaged var date: Date
    @NSManaged var note: String
    @NSManaged var createdAt: Date

    var kind: EntryKind { EntryKind(rawValue: kindRaw) ?? .expense }
    var category: LedgerCategory { LedgerCategory(rawValue: categoryRaw) ?? .other }

    static func allEntriesRequest() -> NSFetchRequest<LedgerEntry> {
        let request = NSFetchRequest<LedgerEntry>(entityName: "LedgerEntry")
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false),
            NSSortDescriptor(key: "id", ascending: false)
        ]
        request.fetchBatchSize = 40
        return request
    }
}
