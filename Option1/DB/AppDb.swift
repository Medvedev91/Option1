import Foundation
import SwiftData
import Cocoa

@Model
class AppDb {
    
    @Attribute(.unique) var bundle: String
    var name: String
    
    init(bundle: String, name: String) {
        self.bundle = bundle
        self.name = name
    }
    
    @MainActor
    func delete() {
        DB.modelContainer.mainContext.delete(self)
        DB.save()
    }
    
    @MainActor
    static func selectAll() -> [AppDb] {
        try! DB.modelContainer.mainContext.fetch(FetchDescriptor<AppDb>())
    }
    
    @MainActor
    static func upsert(runningApps: [NSRunningApplication]) {
        runningApps.forEach { runningApp in
            if runningApp.activationPolicy != .regular {
                return
            }
            guard let bundle: String = runningApp.bundleIdentifier, !bundle.isEmpty else {
                reportLog("AppDb no bundleIdentifier")
                return
            }
            guard let name: String = runningApp.localizedName, !name.isEmpty else {
                reportLog("AppDb no localizedName")
                return
            }
            upsertRaw(bundle: bundle, name: name)
        }
    }
    
    @MainActor
    static func upsertRaw(
        bundle: String,
        name: String,
    ) {
        guard let appDb = selectAll().first(where: { $0.bundle == bundle }) else {
            DB.modelContainer.mainContext.insert(AppDb(bundle: bundle, name: name))
            DB.save()
            reportLog("AppDb.upsertRaw() insert: \(bundle) \(name)")
            return
        }
        if appDb.name == name {
            return
        }
        appDb.name = name
        DB.save()
        reportLog("AppDb.upsertRaw() update: \(bundle) \(name)")
    }
    
    @MainActor
    static func cleanRemoved() {
        selectAll().forEach { appDb in
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: appDb.bundle) == nil {
                reportLog("Deletion \(appDb.name)")
                appDb.delete()
            }
        }
    }
}
