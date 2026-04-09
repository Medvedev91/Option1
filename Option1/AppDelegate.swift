import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        launchTime = time()
        // In logs we see "Warning: Background app automatically schedules for update checks but does
        // not implement gentle reminders...https://sparkle-project.org/documentation/gentle-reminders/".
        // That is because Option1 is "dockless" app - app that does not appear in the Dock.
        // Dockless app do not show alerts about updates automatically. Call it manually.
        sparkleController.updater.checkForUpdatesInBackground()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initData()
        HotKeysUtils.setup()
        MenuBarManager.instance.setup()
        ping()
    }
}

private func initData() {
    Task { @MainActor in
        _ = KvDb.selectOrInsertInitTime()
        
        // todo remove
        if (KvDb.selectOrInsertInitTime() + 30) < time() {
            KvDb.upsertIsDataInited()
        }
        
        if !KvDb.selectIsDataInited() {
            let safariBundle = "com.apple.Safari"
            let calendarBundle = "com.apple.iCal"
            AppDb.upsertRaw(bundle: safariBundle, name: "Safari")
            AppDb.upsertRaw(bundle: calendarBundle, name: "Calendar")
            BindDb.insert(key: "1", workspaceDb: nil, bundle: safariBundle, substring: "")
            BindDb.insert(key: "2", workspaceDb: nil, bundle: calendarBundle, substring: "")
            
            // Favorite Downloads
            let downloadsUri = "/Users/\(NSUserName())/Downloads"
            if isFileExists(downloadsUri) {
                _ = FavoriteDb.insert(bundle: BundleIds.Finder, title: "Downloads", substring: downloadsUri)
            } else {
                reportApi("initData() no downloadsUri \(downloadsUri)")
            }
            KvDb.upsertIsDataInited()
        }
    }
}
