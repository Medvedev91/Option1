import SwiftData

@Model
class OptionTabPinDb {
    
    @Attribute(.unique) var bundle: String
    var sort: Int
    
    init(bundle: String, sort: Int) {
        self.bundle = bundle
        self.sort = sort
    }
    
    ///
    
    @MainActor
    static func selectAll() -> [OptionTabPinDb] {
        try! DB.modelContainer.mainContext.fetch(FetchDescriptor<OptionTabPinDb>())
    }
    
    @MainActor
    static func upsertToTop(bundle: String) {
        let all: [OptionTabPinDb] = selectAll()
        let minSort: Int = all.map(\.sort).min() ?? 0
        guard let pinDb = selectAll().first(where: { $0.bundle == bundle }) else {
            DB.modelContainer.mainContext.insert(OptionTabPinDb(bundle: bundle, sort: minSort - 1))
            DB.save()
            return
        }
        if pinDb.sort == minSort {
            return
        }
        pinDb.sort = minSort - 1
        DB.save()
    }
}
