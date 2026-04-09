import Foundation
import SwiftData

@Model
@MainActor
class FavoriteDb {
    
    @Attribute(.unique) var id: UUID
    var sort: Int
    var bundle: String
    var title: String
    var substring: String
    
    init(
        id: UUID,
        sort: Int,
        bundle: String,
        title: String,
        substring: String,
    ) {
        self.id = id
        self.sort = sort
        self.bundle = bundle
        self.title = title
        self.substring = substring
    }
    
    func buildUiTitle() -> String {
        if !title.isEmpty { return title }
        return selectAppDbOrNil()?.name ?? bundle
    }
    
    func selectAppDbOrNil() -> AppDb? {
        AppDb.selectAll().first{ $0.bundle == bundle }
    }
    
    func updateSort(_ newSort: Int) {
        sort = newSort
        DB.save()
    }
    
    func delete() {
        DB.modelContainer.mainContext.delete(self)
        DB.save()
    }
    
    //
    // For Transaction
    
    static func deleteAll_ForTransaction() {
        selectAllSorted().forEach {
            DB.modelContainer.mainContext.delete($0)
        }
    }
    
    static func insert_ForTransaction(id: UUID, sort: Int, bundle: String, title: String, substring: String) {
        DB.modelContainer.mainContext.insert(FavoriteDb(
            id: id,
            sort: sort,
            bundle: bundle,
            title: title,
            substring: substring,
        ))
    }
    
    ///
    
    static func selectAllSorted() -> [FavoriteDb] {
        try! DB.modelContainer.mainContext.fetch(FetchDescriptor<FavoriteDb>())
            .sorted { $0.sort < $1.sort }
    }
    
    static func insert(
        bundle: String,
        title: String,
        substring: String,
    ) -> FavoriteDb {
        let maxSort: Int = selectAllSorted().map(\.sort).max() ?? 0
        let favoriteDb = FavoriteDb(
            id: UUID(),
            sort: maxSort + 1,
            bundle: bundle,
            title: title.trim(),
            substring: substring.trim(),
        )
        DB.modelContainer.mainContext.insert(favoriteDb)
        DB.save()
        return favoriteDb
    }
}
