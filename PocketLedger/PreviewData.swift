#if DEBUG
import Foundation

enum PreviewData {
    static let persistence: PersistenceController = {
        do {
            let controller = try PersistenceController(inMemory: true)
            let context = controller.container.viewContext
            try LedgerStore.add(amount: "12800", kind: .income, category: .salary,
                                date: Date(), note: "本月工资", in: context)
            try LedgerStore.add(amount: "38.50", kind: .expense, category: .food,
                                date: Date(), note: "和同事一起吃午餐", in: context)
            try LedgerStore.add(amount: "6", kind: .expense, category: .transport,
                                date: Date(), note: "地铁通勤", in: context)
            try LedgerStore.add(amount: "199", kind: .expense, category: .shopping,
                                date: Date(), note: "一双新跑鞋", in: context)
            return controller
        } catch {
            // Preview-only fixture failure, never part of production startup.
            fatalError("Preview fixture failed: \(error)")
        }
    }()
}
#endif
