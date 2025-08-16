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
            queue: OperationQueue.main
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
        
        //        let runLoopSource = AXObserverGetRunLoopSource(observer)
        //        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
    }
}

// https://gist.github.com/hiepnp1990/97048b56711b6017bd1b09731e061233

//
//  MacOS Accessibility Notifications
//  Notice: this version doesn't take into account new apps after this code is executed
//  Created by Phi Hiep Nguyen and AI on 2024-10-08.
//

import Cocoa
import Foundation

// AppObserver: Monitors and reports application activation events on macOS
class AppObserver {
    // Singleton instance for global access
    static let shared = AppObserver()
    
    // Dictionary to store observers for each application, keyed by process ID
    var observers: [pid_t: AXObserver] = [:]
    // Dictionary to track the last activation time for each app, used for debouncing
    var lastActivationTime: [String: Date] = [:]
    // Time interval to prevent duplicate notifications (500 milliseconds)
    let debounceInterval: TimeInterval = 0.5
    
    // Private initializer to enforce singleton pattern
    private init() {}
    
    // Starts the observation process for all running applications
    func start() {
        // Check for accessibility permissions
        guard self.checkAccessibilityPermissions() else {
            print("Accessibility permissions are required. Please grant them in System Preferences > Security & Privacy > Privacy > Accessibility.")
            print("After granting permissions, please restart the application.")
            exit(1)
        }
        
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications.filter { $0.activationPolicy == .regular }
        
        // Set up observers for each running application
        for app in runningApps {
            if app.bundleIdentifier == "io.option1.app" || app.bundleIdentifier == "com.apple.dt.Xcode" {
                continue
            }
            addObserver(for: app)
        }
        
        // Start the run loop to process events
        // todo
//        RunLoop.current.run()
    }
    
    // Adds an accessibility observer for a given application
    func addObserver(for app: NSRunningApplication) {
        let pid = app.processIdentifier
        
        var observer: AXObserver?
        // Callback function triggered when an application is activated
        let callback: AXObserverCallback = { (observer, element, notification, refcon) in
            guard let appRefcon = refcon else { return }
            let appPid = Unmanaged<NSNumber>.fromOpaque(appRefcon).takeUnretainedValue().int32Value
            if let activatedApp = NSRunningApplication(processIdentifier: appPid) {
                let appName = activatedApp.localizedName ?? activatedApp.bundleIdentifier ?? "Unknown"
                // Use the shared instance to debounce notifications
                AppObserver.shared.handleNotification(appName: appName, notification: notification, element: element)
            }
        }
        
        // Create the accessibility observer
        let createError = AXObserverCreate(pid, callback, &observer)
        guard createError == .success, let observer = observer else {
            print("Failed to create observer for \(app.localizedName ?? "Unknown")")
            return
        }
        
        // Create an accessibility element for the application
        let axApp = AXUIElementCreateApplication(pid)
        // Store the process ID as the refcon (reference constant) for later use
        let appPidRef = Unmanaged.passUnretained(NSNumber(value: pid)).toOpaque()
        
        // Add notification for application activation
        var addError = AXObserverAddNotification(observer, axApp, kAXApplicationActivatedNotification as CFString, appPidRef)
        if addError != .success {
            print("Failed to add activation notification for \(app.localizedName ?? "Unknown")")
        }
        
        // Add notification for frontmost window changed
//        addError = AXObserverAddNotification(observer, axApp, kAXFocusedWindowChangedNotification as CFString, appPidRef)
//        if addError != .success {
//            print("Failed to add window focus notification for \(app.localizedName ?? "Unknown")")
//        }
        
        addError = AXObserverAddNotification(observer, axApp, kAXFocusedWindowChangedNotification as CFString, appPidRef)
        addError = AXObserverAddNotification(observer, axApp, kAXMainWindowChangedNotification as CFString, appPidRef)
        addError = AXObserverAddNotification(observer, axApp, kAXWindowCreatedNotification as CFString, appPidRef)
        addError = AXObserverAddNotification(observer, axApp, kAXApplicationHiddenNotification as CFString, appPidRef)
        addError = AXObserverAddNotification(observer, axApp, kAXApplicationShownNotification as CFString, appPidRef)

        // Add the observer to the current run loop
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
        
        // Store the observer in the dictionary
        observers[pid] = observer
    }
    
    // Debounces notifications to prevent duplicate reports for rapid app switches
    func handleNotification(appName: String, notification: CFString, element: AXUIElement) {
        let currentTime = Date()
        if let lastTime = lastActivationTime[appName],
           currentTime.timeIntervalSince(lastTime) < debounceInterval {
            return // Ignore this notification as it's too soon after the last one
        }
        
        // Update the last activation time for this app
        lastActivationTime[appName] = currentTime
        
        if notification as String == kAXApplicationActivatedNotification as String {
            // todo my
//            print("Notification: Application Activated for app: \(appName)")
//            try! WindowsManager.getFocusedWindowOrNil()!.title()!
            var windowTitle: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &windowTitle)
            if let title = windowTitle as? String {
                // todo my
//                print("Notification: Frontmost Window Changed for app: \(appName)")
//                print("Title: \(title)")
//                try! WindowsManager.getFocusedWindowOrNil()
            }
        } else if notification as String == kAXFocusedWindowChangedNotification as String {
            var windowTitle: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &windowTitle)
            if let title = windowTitle as? String {
                // todo my
//                print("Notification: Frontmost Window Changed for app: \(appName)")
//                print("Current Window Title: \(title)")
//                try! WindowsManager.getFocusedWindowOrNil()
            }
        } else {
//            print("notif \(notification)")
//            try! WindowsManager.getFocusedWindowOrNil()
            var windowTitle: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &windowTitle)
            if let title = windowTitle as? String {
                // todo my
//                print("Notification: Frontmost Window Changed for app: \(appName)")
//                print("Title: \(title)")
//                try! WindowsManager.getFocusedWindowOrNil()
            }
        }
//        var windowId: CFTypeRef?
//        AXUIElementCopyAttributeValue(element, kAXIdentifierAttribute as CFString, &windowId)
        
        var windowTitle: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &windowTitle)
        
        ///
        var pid = pid_t(0)
        AXUIElementGetPid(element, &pid)
        try! AXUIElementCreateApplication(pid).focusedWindow()
//        print("\(notification) \(pid) \(try! WindowsManager.getFocusedWindowOrNil()!.title() ?? "--")")
        print("\(notification) \(pid) \((windowTitle as? String) ?? "--")")
    }
    
    // Clean up observers when the AppObserver is deallocated
    deinit {
        for (_, observer) in observers {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
        }
    }
    
    // Check for accessibility permissions
    func checkAccessibilityPermissions() -> Bool {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}

// Create a shared instance of AppObserver and start monitoring
