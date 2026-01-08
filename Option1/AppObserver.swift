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
                // Если не использовать Task то приложение подвисает на
                // несколько секунд, по этому initialTaskOrDispatch = true.
                // Нет смысла в initialDelaySeconds т.к. окна давно запущены.
                addObserver(app: app, initialTaskOrDispatch: true, initialDelaySeconds: 0)
            }
    }
    
    func addObserver(app: NSRunningApplication, initialTaskOrDispatch: Bool, initialDelaySeconds: CGFloat) {
        let pid = app.processIdentifier
        
        initCachedWindows(app: app, taskOrDispatch: initialTaskOrDispatch, delaySeconds: initialDelaySeconds)
        
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
        
        let errorText = "AppObserver.addObserver() \(app.bundleIdentifier ?? "NO-BUNDLE") error"
        func attachNotification(_ notification: String) {
            let error = AXObserverAddNotification(observer, axApp, notification as CFString, appPidRef)
            if error != .success {
                if error == .cannotComplete {
                    reportLog("\(errorText) \(notification) \(error)")
                } else {
                    reportApi("\(errorText) \(notification) \(error)")
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            
            // Документация к каждому из событий ниже в handleNotification()
            attachNotification(kAXApplicationActivatedNotification)
            attachNotification(kAXFocusedWindowChangedNotification)
            attachNotification(kAXTitleChangedNotification)

            CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
            
            self.observers[pid] = observer
        }
    }
}

///

// Не понимаю как работает, но иногда можно вызывать
// из Task{} а иногда при вызове получаю крэш.
private func initCachedWindows(
    app: NSRunningApplication,
    taskOrDispatch: Bool,
    delaySeconds: CGFloat,
) {
    // Fill Initial CachedWindow
    func initCachedWindow() {
        do {
            try CachedWindow.addByApp(app)
        } catch {
            reportApi("AppObserver.addObserver() taskOrDispatch:\(taskOrDispatch) error:\(error)")
        }
    }
    if taskOrDispatch {
        Task {
            try await Task.sleep(nanoseconds: UInt64(delaySeconds * CGFloat(1_000_000_000)))
            initCachedWindow()
        }
    } else {
        DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) {
            initCachedWindow()
        }
    }
}

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
            // Срабатывает на изменение заголовка у окна.
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
