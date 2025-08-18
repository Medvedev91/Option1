//
// Based on https://gist.github.com/Medvedev91/58df7d63be01bd5a0f8880565f36d8b8
//

import Foundation
import Cocoa

class AppObserver {
    
    static let shared = AppObserver()
    
    private var observers: [pid_t: AXObserver] = [:]
    
    func restart() {
        observers.forEach {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource($0.value), .defaultMode)
        }
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .forEach { addObserver(app: $0) }
    }
    
    func addObserver(app: NSRunningApplication) {
        let pid = app.processIdentifier
        
        var observer: AXObserver?
        // Callback function triggered when an application is activated
        let callback: AXObserverCallback = { (observer, element, notification, refcon) in
            guard let appRefcon = refcon else { return }
            let appPid = Unmanaged<NSNumber>.fromOpaque(appRefcon).takeUnretainedValue().int32Value
            if let activatedApp = NSRunningApplication(processIdentifier: appPid) {
                let appName = activatedApp.localizedName ?? activatedApp.bundleIdentifier ?? "Unknown"
                AppObserver.shared.handleNotification(appName: appName, notification: notification, axElement: element)
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
        
        // todo check errors like if addError != .success
        addError = AXObserverAddNotification(observer, axApp, kAXFocusedWindowChangedNotification as CFString, appPidRef)
        addError = AXObserverAddNotification(observer, axApp, kAXMainWindowChangedNotification as CFString, appPidRef)
        addError = AXObserverAddNotification(observer, axApp, kAXWindowCreatedNotification as CFString, appPidRef)
        addError = AXObserverAddNotification(observer, axApp, kAXApplicationHiddenNotification as CFString, appPidRef)
        addError = AXObserverAddNotification(observer, axApp, kAXApplicationShownNotification as CFString, appPidRef)
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
        
        observers[pid] = observer
    }
    
    private func handleNotification(appName: String, notification: CFString, axElement: AXUIElement) {
        // let notificationString: String = notification as String
        // var windowTitle: CFTypeRef?
        // AXUIElementCopyAttributeValue(axElement, kAXTitleAttribute as CFString, &windowTitle)
        // print("handleNotification \(appName) \(notificationString) \((windowTitle as? String) ?? "--")")
        
        do {
            _ = try axElement.focusedWindow()
        } catch {
            reportApi("AppObserver.handleNotification() error:\n\(error)")
        }
    }
}
