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
    // Donations Last Reponse Time
    
    @MainActor
    static func selectDonationsLastAlertTimeOrNil() -> Int? {
        selectByKeyOrNil(DONATIONS_LAST_ALERT_TIME_KEY).map { Int($0.value)! }
    }
    
    @MainActor
    static func upsertDonationsLastAlertTime() {
        upsert(key: DONATIONS_LAST_ALERT_TIME_KEY, value: String(time()))
    }
    
    //
    // Activation Transaction ID
    
    @MainActor
    static func selectActivationTransactionIdOrNil() -> String? {
        selectByKeyOrNil(ACTIVATION_TRANSACTION_ID_KEY)?.value
    }
    
    @MainActor
    static func upsertActivationTransactionId(_ activationTransactionId: String) {
        upsert(key: ACTIVATION_TRANSACTION_ID_KEY, value: activationTransactionId)
    }
    
    //
    // Token
    
    @MainActor
    static func selectTokenOrNil() -> String? {
        selectByKeyOrNil(TOKEN_KEY)?.value
    }
    
    @MainActor
    static func upsertToken(_ token: String) {
        upsert(key: TOKEN_KEY, value: token)
    }
}

private let TOKEN_KEY = "token"
private let INIT_TIME_KEY = "init-time"
private let ACTIVATION_TRANSACTION_ID_KEY = "activation-transaction-id"
private let DONATIONS_LAST_ALERT_TIME_KEY = "donations-last-alert-time"
