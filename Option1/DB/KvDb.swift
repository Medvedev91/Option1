import SwiftData

@Model
class KvDb {
    
    @Attribute(.unique) var key: String
    var value: String
    
    init (key: String, value: String) {
        self.key = key
        self.value = value
    }
    
    @MainActor
    static func selectAll() -> [KvDb] {
        try! DB.modelContainer.mainContext.fetch(FetchDescriptor<KvDb>())
    }
    
    @MainActor
    static func selectByKeyOrNil(_ key: String) -> KvDb? {
        selectAll().first { $0.key == key }
    }
    
    //
    // Token
    
    @MainActor
    static func getTokenOrNil() -> String? {
        selectByKeyOrNil(TOKEN_KEY)?.value
    }
    
    @MainActor
    static func upsertToken(_ token: String) {
        guard let kvDb = selectByKeyOrNil(TOKEN_KEY) else {
            DB.modelContainer.mainContext.insert(KvDb(key: TOKEN_KEY, value: token))
            DB.save()
            return
        }
        kvDb.value = token
        DB.save()
    }
}

private let TOKEN_KEY = "token"
