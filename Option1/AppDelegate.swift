import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // In logs we see "Warning: Background app automatically schedules for update checks but does
        // not implement gentle reminders...https://sparkle-project.org/documentation/gentle-reminders/".
        // That is because Option 1 is "dockless" app - app that does not appear in the Dock.
        // Dockless app do not show alerts about updates automatically. Call it manually.
        sparkleController.updater.checkForUpdatesInBackground()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initData()
        HotKeysUtils.setup()
        MenuManager.instance.setup()
        ping()
    }
}

private func initData() {
    Task { @MainActor in
        _ = KvDb.selectOrInsertInitTime()
        
        if BindDb.selectAll().isEmpty {
            BindDb.insert(key: "1", workspaceDb: nil, bundle: "com.apple.Safari", substring: "")
            BindDb.insert(key: "2", workspaceDb: nil, bundle: "com.apple.iCal", substring: "")
        }
    }
}
