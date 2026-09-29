import CoreData

final class PersistenceController {
    let container: NSPersistentContainer

    init(inMemory: Bool = false) throws {
        container = NSPersistentContainer(name: "PocketLedger", managedObjectModel: Self.makeModel())
        let description = NSPersistentStoreDescription()
        if inMemory {
            description.type = NSInMemoryStoreType
        } else {
            let directory = NSPersistentContainer.defaultDirectoryURL()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            description.url = directory.appendingPathComponent("PocketLedger.sqlite")
            description.type = NSSQLiteStoreType
        }
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        container.viewContext.name = "LedgerViewContext"
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.undoManager = nil
    }

    // A code-defined Core Data model keeps the schema readable in a portfolio.
    // Schema changes in later releases must keep a versioned source model for migration.
    private static func makeModel() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = "LedgerEntry"
        entity.managedObjectClassName = NSStringFromClass(LedgerEntry.self)
        let fields: [(String, NSAttributeType)] = [
            ("id", .UUIDAttributeType), ("amountCents", .integer64AttributeType),
            ("kindRaw", .stringAttributeType), ("categoryRaw", .stringAttributeType),
            ("date", .dateAttributeType), ("note", .stringAttributeType),
            ("createdAt", .dateAttributeType)
        ]
        entity.properties = fields.map { name, type in
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = false
            if name == "amountCents" {
                attribute.setValidationPredicates([
                    NSPredicate(format: "SELF > 0"),
                    NSPredicate(format: "SELF <= %lld", Money.maximumCents)
                ], withValidationWarnings: ["金额必须大于零", "金额超出上限"])
            }
            return attribute
        }
        entity.uniquenessConstraints = [["id"]]
        if let date = entity.attributesByName["date"] {
            entity.indexes = [NSFetchIndexDescription(name: "byDate", elements: [
                NSFetchIndexElementDescription(property: date, collationType: .binary)
            ])]
        }
        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }
}

enum LedgerStore {
    @discardableResult
    static func add(amount: String, kind: EntryKind, category: LedgerCategory,
                    date: Date, note: String, in context: NSManagedObjectContext) throws -> LedgerEntry {
        let cents = try Money.parse(amount)
        guard kind.categories.contains(category) else { throw LedgerError.invalidCategory }
        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanNote.count <= 100 else { throw LedgerError.noteTooLong }
        let entry = LedgerEntry(context: context)
        entry.id = UUID()
        entry.amountCents = cents
        entry.kindRaw = kind.rawValue
        entry.categoryRaw = category.rawValue
        entry.date = date
        entry.note = cleanNote
        entry.createdAt = Date()
        do {
            try context.save()
            return entry
        } catch {
            context.rollback()
            throw error
        }
    }

    static func delete(_ entries: [LedgerEntry], in context: NSManagedObjectContext) throws {
        entries.forEach(context.delete)
        do { try context.save() }
        catch { context.rollback(); throw error }
    }
}
