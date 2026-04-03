import Foundation
import SwiftData

@Model
@MainActor
class FavoriteDb {
    
    @Attribute(.unique) var id: UUID
    var sort: Int
    var bundle: String
    var name: String
    var substring: String
    
    init(
        id: UUID,
        sort: Int,
        bundle: String,
        name: String,
        substring: String,
    ) {
        self.id = id
        self.sort = sort
        self.bundle = bundle
        self.name = name
        self.substring = substring
    }
    
    func buildUiName() -> String {
        if !name.isEmpty { return name }
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
    
    ///
    
    static func selectAllSorted() -> [FavoriteDb] {
        try! DB.modelContainer.mainContext.fetch(FetchDescriptor<FavoriteDb>())
            .sorted { $0.sort < $1.sort }
    }
    
    static func insert(
        bundle: String,
        name: String,
        substring: String,
    ) -> FavoriteDb {
        let maxSort: Int = selectAllSorted().map(\.sort).max() ?? 0
        let favoriteDb = FavoriteDb(
            id: UUID(),
            sort: maxSort + 1,
            bundle: bundle,
            name: name.trim(),
            substring: substring.trim(),
        )
        DB.modelContainer.mainContext.insert(favoriteDb)
        DB.save()
        return favoriteDb
    }
}
