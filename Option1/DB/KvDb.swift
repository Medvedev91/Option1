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
    
    //
    // Token
    
    @MainActor
    static func getTokenKvDbOrNil() -> KvDb? {
        selectAll().first { $0.key == TOKEN_KEY }
    }
    
    @MainActor
    static func getTokenOrNil() -> String? {
        getTokenKvDbOrNil()?.value
    }
    
    @MainActor
    static func upsertToken(_ token: String) {
        guard let kvDb = getTokenKvDbOrNil() else {
            DB.modelContainer.mainContext.insert(KvDb(key: TOKEN_KEY, value: token))
            DB.save()
            return
        }
        kvDb.value = token
        DB.save()
    }
}

private let TOKEN_KEY = "token"
