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
    
    @MainActor
    static func upsert(key: String, value: String) {
        guard let kvDb = selectByKeyOrNil(key) else {
            DB.modelContainer.mainContext.insert(KvDb(key: key, value: value))
            DB.save()
            return
        }
        kvDb.value = value
        DB.save()
    }
    
    ///
    
    @MainActor
    static func selectOrInsertInitTime() -> Int {
        if let initTime = KvDb.selectByKeyOrNil(INIT_TIME_KEY)?.value {
            return Int(initTime)!
        }
        let now = time()
        DB.modelContainer.mainContext.insert(KvDb(key: INIT_TIME_KEY, value: String(now)))
        DB.save()
        return Int(now)
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
private let INIT_TIME_KEY = "init-time"
