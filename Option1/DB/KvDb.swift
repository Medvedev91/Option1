import SwiftData

@Model
@MainActor
class KvDb {
    
    @Attribute(.unique) var key: String
    var value: String
    
    init (key: String, value: String) {
        self.key = key
        self.value = value
    }
    
    static func selectAll() -> [KvDb] {
        try! DB.modelContainer.mainContext.fetch(FetchDescriptor<KvDb>())
    }
    
    static func selectByKeyOrNil(_ key: String) -> KvDb? {
        selectAll().first { $0.key == key }
    }
    
    static func upsert(key: String, value: String) {
        guard let kvDb = selectByKeyOrNil(key) else {
            DB.modelContainer.mainContext.insert(KvDb(key: key, value: value))
            DB.save()
            return
        }
        kvDb.value = value
        DB.save()
    }
    
    //
    // For Transaction
    
    static func deleteAll_ForTransaction() {
        selectAll().forEach {
            DB.modelContainer.mainContext.delete($0)
        }
    }
    
    static func insert_ForTransaction(key: String, value: String) {
        DB.modelContainer.mainContext.insert(KvDb(key: key, value: value))
    }
    
    ///
    
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
    // Is Option-Tab Enabled
    
    static func selectIsOptionTabEnabled() -> Bool {
        selectByKeyOrNil(IS_OPTION_TAB_ENABLED_KEY).map { $0.value == "1" } ?? true
    }
    
    static func upsertIsOptionTabEnabled(_ isEnabled: Bool) {
        upsert(key: IS_OPTION_TAB_ENABLED_KEY, value: isEnabled ? "1" : "0")
    }
    
    //
    // Is Keep Jumps Global
    
    static func selectIsKeepJumpsGlobal() -> Bool {
        selectByKeyOrNil(IS_KEEP_JUMPS_GLOBAL_KEY).map { $0.value == "1" } ?? true
    }
    
    static func upsertIsKeepJumpsGlobal(_ isKeep: Bool) -> Bool {
        upsert(key: IS_KEEP_JUMPS_GLOBAL_KEY, value: isKeep ? "1" : "0")
        return isKeep
    }
    
    //
    // Option-Tab Mode
    
    static func selectOptionTabDbMode() -> OptionTabDbMode {
        let defaultMode: OptionTabDbMode = .jk
        guard let rawValue: String = selectByKeyOrNil(OPTION_TAB_DB_MODE_KEY)?.value else {
            return defaultMode
        }
        return OptionTabDbMode.allCases.first { String($0.rawValue) == rawValue } ?? defaultMode
    }
    
    static func upsertOptionTabDbMode(_ mode: OptionTabDbMode) {
        upsert(key: OPTION_TAB_DB_MODE_KEY, value: String(mode.rawValue))
    }
    
    //
    // Is Display in Menu Bar
    
    static func selectIsDisplayInMenuBar() -> Bool {
        selectByKeyOrNil(IS_DISPLAY_IN_MENU_BAR_KEY).map { $0.value == "1" } ?? true
    }
    
    static func upsertIsDisplayInMenuBar(_ isEnabled: Bool) {
        upsert(key: IS_DISPLAY_IN_MENU_BAR_KEY, value: isEnabled ? "1" : "0")
    }
    
    //
    // Donations Last Reponse Time
    
    static func selectDonationsLastAlertTimeOrNil() -> Int? {
        selectByKeyOrNil(DONATIONS_LAST_ALERT_TIME_KEY).map { Int($0.value)! }
    }
    
    static func upsertDonationsLastAlertTime() {
        upsert(key: DONATIONS_LAST_ALERT_TIME_KEY, value: String(time()))
    }
    
    //
    // Activation Email
    
    static func selectActivationEmailOrNil() -> String? {
        selectByKeyOrNil(ACTIVATION_EMAIL_KEY)?.value
    }
    
    static func upsertActivationEmail(_ activationEmail: String) {
        upsert(key: ACTIVATION_EMAIL_KEY, value: activationEmail)
    }
    
    //
    // Token
    
    static func selectTokenOrNil() -> String? {
        selectByKeyOrNil(TOKEN_KEY)?.value
    }
    
    static func upsertToken(_ token: String) {
        upsert(key: TOKEN_KEY, value: token)
    }
}

private let TOKEN_KEY = "token"
private let INIT_TIME_KEY = "init-time"
private let ACTIVATION_EMAIL_KEY = "activation-email"
private let DONATIONS_LAST_ALERT_TIME_KEY = "donations-last-alert-time"
private let IS_KEEP_JUMPS_GLOBAL_KEY = "is-keep-jumps-global"
private let IS_OPTION_TAB_ENABLED_KEY = "is-option-tab-enabled"
private let OPTION_TAB_DB_MODE_KEY = "option-tab-db-mode"
private let IS_DISPLAY_IN_MENU_BAR_KEY = "is-display-in-menu-bar"
