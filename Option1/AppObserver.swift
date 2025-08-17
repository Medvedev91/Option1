//
// Based on https://gist.github.com/hiepnp1990/97048b56711b6017bd1b09731e061233
//

import Foundation
import Cocoa

class AppObserver {
    
    static let shared = AppObserver()
    
    var observers: [pid_t: AXObserver] = [:]
    
    func start() {
        let runningApps: [NSRunningApplication] = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular
        }
        for app in runningApps {
            addObserver(for: app)
        }
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
        
        let createError = AXObserverCreate(pid, callback, &observer)
        guard createError == .success, let observer = observer else {
            print("Failed to create observer for \(app.localizedName ?? "Unknown")")
            return
        }
        
        // Create an accessibility element for the application
        let axApp = AXUIElementCreateApplication(pid)
        // Store the process ID as the refcon (reference constant) for later use
        let appPidRef = Unmanaged.passUnretained(NSNumber(value: pid)).toOpaque()
        
        var addError = AXObserverAddNotification(observer, axApp, kAXApplicationActivatedNotification as CFString, appPidRef)
        if addError != .success {
            print("Failed to add activation notification for \(app.localizedName ?? "Unknown")")
        }
        
        // Add notification for frontmost window changed
//        addError = AXObserverAddNotification(observer, axApp, kAXFocusedWindowChangedNotification as CFString, appPidRef)
//        if addError != .success {
//            print("Failed to add window focus notification for \(app.localizedName ?? "Unknown")")
//        }
        
        // todo check errors
        addError = AXObserverAddNotification(observer, axApp, kAXFocusedWindowChangedNotification as CFString, appPidRef)
        addError = AXObserverAddNotification(observer, axApp, kAXMainWindowChangedNotification as CFString, appPidRef)
        addError = AXObserverAddNotification(observer, axApp, kAXWindowCreatedNotification as CFString, appPidRef)
        addError = AXObserverAddNotification(observer, axApp, kAXApplicationHiddenNotification as CFString, appPidRef)
        addError = AXObserverAddNotification(observer, axApp, kAXApplicationShownNotification as CFString, appPidRef)

        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
        
        observers[pid] = observer
    }
    
    func handleNotification(appName: String, notification: CFString, element: AXUIElement) {
        if notification as String == kAXApplicationActivatedNotification as String {
            var windowTitle: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &windowTitle)
        } else if notification as String == kAXFocusedWindowChangedNotification as String {
            var windowTitle: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &windowTitle)
        } else {
            var windowTitle: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &windowTitle)
        }
        
        var windowTitle: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &windowTitle)
        
        ///
        
        var pid = pid_t(0)
        AXUIElementGetPid(element, &pid)
        do {
            try AXUIElementCreateApplication(pid).focusedWindow()
        } catch {
            reportApi("AppObserver.handleNotification() error:\n\(error)")
        }
    }
}
