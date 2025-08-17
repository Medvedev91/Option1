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
        HotKeysUtils.setup() 
        MenuManager.setup()
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: OperationQueue.main,
        ) { (notification: Notification) in
            // https://developer.apple.com/documentation/appkit/nsworkspace/didactivateapplicationnotification
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                reportApi("didActivateApplicationNotification nil")
                return
            }
            AppObserver.shared.addObserver(for: app)
        }
        
        AppObserver.shared.start()
    }
}
