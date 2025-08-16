import AppKit

var localeChangeObserver: Any?
let appObserver = AppObserver.shared

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
            //            forName: NSWorkspace.activeSpaceDidChangeNotification,
            //            forName: NSWorkspace.didChangeFileLabelsNotification,
            object: nil,
            queue: OperationQueue.main,
        ) { (notification: Notification) in
            if let app = WindowsManager.getActiveApplicationOrNil() {
                Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    print("NSWorkspace \(app.bundleIdentifier)")
                    appObserver.addObserver(for: app)
                }
            }
//            let wOrNil = try! WindowsManager.getFocusedWindowOrNil()
        }
        
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: OperationQueue.main
        ) { (notification: Notification) in
            //            print("NotificationCenter")
        }
        
        appObserver.start()
    }
}
