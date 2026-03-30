import SwiftData

@Model
class OptionTabPinDb {
    
    @Attribute(.unique) var bundle: String
    var sort: Int
    
    init(bundle: String, sort: Int) {
        self.bundle = bundle
        self.sort = sort
    }
    
    @MainActor
    func updateSort(_ newSort: Int) {
        sort = newSort
        DB.save()
    }
    
    //
    // For Transaction
    
    @MainActor
    static func deleteAll_ForTransaction() {
        selectAll().forEach {
            DB.modelContainer.mainContext.delete($0)
        }
    }
    
    @MainActor
    static func insert_ForTransaction(bundle: String, sort: Int) {
        DB.modelContainer.mainContext.insert(OptionTabPinDb(
            bundle: bundle,
            sort: sort,
        ))
    }
    
    ///
    
    @MainActor
    static func selectAll() -> [OptionTabPinDb] {
        try! DB.modelContainer.mainContext.fetch(FetchDescriptor<OptionTabPinDb>())
    }
    
    @MainActor
    static func upsertToTop(bundle: String) {
        let all: [OptionTabPinDb] = selectAll()
        let maxSort: Int = all.map(\.sort).max() ?? 0
        guard let pinDb = selectAll().first(where: { $0.bundle == bundle }) else {
            DB.modelContainer.mainContext.insert(OptionTabPinDb(bundle: bundle, sort: maxSort + 1))
            DB.save()
            return
        }
        if pinDb.sort == maxSort {
            return
        }
        pinDb.sort = maxSort + 1
        DB.save()
    }
    
    @MainActor
    static func delete(bundle: String) {
        guard let pinDb = selectAll().first(where: { $0.bundle == bundle }) else {
            return
        }
        DB.modelContainer.mainContext.delete(pinDb)
        DB.save()
    }
}
