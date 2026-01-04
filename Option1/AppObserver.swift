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
            .forEach { app in
                addObserver(app: app)
                // `Task {}` BECAUSE OF SUPER SLOW LOOP BY ALL APPS USING `.allWindows()`
                Task {
                    let pid = app.processIdentifier
                    let axElement = AXUIElementCreateApplication(pid)
                    do {
                        try axElement.allWindows(pid).forEach { axuiElement in
                            try CachedWindow.addByAxuiElement(nsRunningApplication: app, axuiElement: axuiElement)
                        }
                    } catch {
                        reportApi("AppObserver.restart() error:\n\(error)")
                    }
                }
            }
        
    }
    
    func addObserver(app: NSRunningApplication) {
        let pid = app.processIdentifier
        var observer: AXObserver?
        // Callback function triggered when an application is activated
        let callback: AXObserverCallback = { (observer, axuiElement, notification, refcon) in
            guard let appRefcon = refcon else { return }
            let appPid = Unmanaged<NSNumber>.fromOpaque(appRefcon).takeUnretainedValue().int32Value
            if let activatedApp = NSRunningApplication(processIdentifier: appPid) {
                let appName = activatedApp.localizedName ?? activatedApp.bundleIdentifier ?? "Unknown"
                handleNotification(
                    app: activatedApp,
                    appName: appName,
                    notification: notification,
                    axuiElement: axuiElement,
                )
            }
        }
        
        let createError = AXObserverCreate(pid, callback, &observer)
        guard createError == .success, let observer = observer else {
            reportApi("Failed to create observer for \(app.localizedName ?? "Unknown")")
            return
        }
        
        // Create an accessibility element for the application
        let axApp = AXUIElementCreateApplication(pid)
        // Store the process ID as the refcon (reference constant) for later use
        let appPidRef = Unmanaged.passUnretained(NSNumber(value: pid)).toOpaque()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            
            ///
            /// Документация к каждом из событий ниже в handleNotification()
            ///
            
            let e1 = AXObserverAddNotification(observer, axApp, kAXApplicationActivatedNotification as CFString, appPidRef)
            if e1 != .success {
                reportApi("AppObserver.addObserver() kAXApplicationActivatedNotification \(e1)")
            }
            
            let e2 = AXObserverAddNotification(observer, axApp, kAXFocusedWindowChangedNotification as CFString, appPidRef)
            if e2 != .success {
                reportApi("AppObserver.addObserver() kAXApplicationActivatedNotification \(e2)")
            }
            
            let e3 = AXObserverAddNotification(observer, axApp, kAXTitleChangedNotification as CFString, appPidRef)
            if e3 != .success {
                reportApi("AppObserver.addObserver() kAXApplicationActivatedNotification \(e3)")
            }
            
            CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
            
            self.observers[pid] = observer
        }
    }
}

///

private func handleNotification(
    app: NSRunningApplication,
    appName: String,
    notification: CFString,
    axuiElement: AXUIElement,
) {
    do {
        // Срабатывает при фокусе окна другого приложения.
        // Нужно использовать `focusedWindow()`
        if (String(notification) == kAXApplicationActivatedNotification) {
            if let focusedWindow = try axuiElement.focusedWindow() {
                try CachedWindow.addByAxuiElement(nsRunningApplication: app, axuiElement: focusedWindow)
            }
        } else if (String(notification) == kAXFocusedWindowChangedNotification) {
            // Срабатывает при смене окна у текущего приложения. Например между
            // окнами Xcode. Иногда срабатывает при фокусе на другое приложение.
            // Использовать напрямую `axuiElement`, а не `.focusedWindow()`.
            try CachedWindow.addByAxuiElement(nsRunningApplication: app, axuiElement: axuiElement)
        } else if (String(notification) == kAXTitleChangedNotification) {
            // Срабатывает на изменение заголовка и окна.
            // Использовать напрямую `axuiElement`, а не `.focusedWindow()`.
            // Частые вызовы с пустым `.title()`. Их нужно пропускать.
            // kAXTitleChangedNotification исправлял баг при отладке запуска IntelliJ Idea:
            // при холодном старте Idea в которой откроется несколько окон, у части окон
            // не полные имена, соответственно поиск по заголовку может не сработать.
            if let title = try axuiElement.title(), title.isEmpty == false {
                try CachedWindow.addByAxuiElement(nsRunningApplication: app, axuiElement: axuiElement)
            }
        } else {
            reportApi("AppObserver.handleNotification() unhandled notification")
        }
    } catch {
        reportApi("AppObserver.handleNotification() error:\n\(error)")
    }
}
