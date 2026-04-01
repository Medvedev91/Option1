import AppKit
import HotKey

private var keepHotKeyHandlers: [HotKey] = []

//
// Option-Tab

private let onOptionTabLongPressFirstDelay: UInt64 = 250_000_000
private let onOptionTabLongPressRepeatDelay: UInt64 = 30_000_000
private var onOptionTabPressedTask: Task<(), Error>? = nil
private var onOptionShiftTabPressedTask: Task<(), Error>? = nil

private var optionTabHotKeyHandlers: [HotKey] = []
private var optionTabLocalMonitorForEvents: Any?
private var optionTabGlobalMonitorForEvents: Any?

class HotKeysUtils {
    
    static let keys: [Key] = [.one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .zero]
    
    static var isOptionTabPressedUpOrDownOrNil: Bool? {
        if onOptionTabPressedTask != nil { return false }
        if onOptionShiftTabPressedTask != nil { return true }
        return nil
    }
    
    @MainActor
    static func setup() {
        keys.forEach { key in
            keepHotKeyHandlers.append(
                HotKey(
                    key: key,
                    modifiers: [.option],
                    keyDownHandler: {
                        Task { @MainActor in
                            OptionTabManager.instance.closeWindow()
                            handleRun(key: key)
                        }
                    },
                )
            )
        }
        
        if OptionTabManager.instance.isEnabled {
            enableOptionTab()
        }
    }
    
    @MainActor
    static func enableOptionTab() {
        optionTabHotKeyHandlers.append(
            HotKey(
                key: .escape,
                modifiers: [.option],
                keyDownHandler: {
                    OptionTabManager.instance.closeWindow()
                },
            )
        )
        
        optionTabHotKeyHandlers.append(
            HotKey(
                key: .tab,
                modifiers: [.option],
                keyDownHandler: {
                    OptionTabManager.instance.onOptionTabPressed(fromJk: false)
                    onOptionTabPressedTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: onOptionTabLongPressFirstDelay)
                        while onOptionTabPressedTask != nil {
                            try? await Task.sleep(nanoseconds: onOptionTabLongPressRepeatDelay)
                            OptionTabManager.instance.onOptionTabPressed(fromJk: false)
                        }
                    }
                },
                keyUpHandler: {
                    onOptionTabPressedTask?.cancel()
                    onOptionTabPressedTask = nil
                },
            )
        )
        
        optionTabHotKeyHandlers.append(
            HotKey(
                key: .tab,
                modifiers: [.option, .shift],
                keyDownHandler: {
                    OptionTabManager.instance.onOptionShiftTabPressed(fromJk: false)
                    onOptionShiftTabPressedTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: onOptionTabLongPressFirstDelay)
                        while onOptionShiftTabPressedTask != nil {
                            try? await Task.sleep(nanoseconds: onOptionTabLongPressRepeatDelay)
                            OptionTabManager.instance.onOptionShiftTabPressed(fromJk: false)
                        }
                    }
                },
                keyUpHandler: {
                    onOptionShiftTabPressedTask?.cancel()
                    onOptionShiftTabPressedTask = nil
                },
            )
        )
        
        optionTabLocalMonitorForEvents = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event -> NSEvent? in
            if !event.modifierFlags.contains(.option) {
                OptionTabManager.instance.onOptionKeyUp()
            }
            return event
        }
        optionTabGlobalMonitorForEvents = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            if !event.modifierFlags.contains(.option) {
                OptionTabManager.instance.onOptionKeyUp()
            }
        }
    }
    
    static func disableOptionTab() {
        // Hot Keys
        optionTabHotKeyHandlers.forEach { hotKey in
            hotKey.isPaused = true
        }
        optionTabHotKeyHandlers.removeAll()
        // Modifier Events
        if let optionTabLocalMonitorForEventsLocal = optionTabLocalMonitorForEvents {
            NSEvent.removeMonitor(optionTabLocalMonitorForEventsLocal)
            optionTabLocalMonitorForEvents = nil
        }
        if let optionTabGlobalMonitorForEventsLocal = optionTabGlobalMonitorForEvents {
            NSEvent.removeMonitor(optionTabGlobalMonitorForEventsLocal)
            optionTabGlobalMonitorForEvents = nil
        }
    }
    
    @MainActor
    static func handleRun(key: Key) {
        ping()
        _ = isAccessibilityGranted(showDialog: true)
        
        if DonationsAlertUtils.checkUp() {
            return
        }
        
        let bindsDb = BindDb.selectAll()
        
        guard let bindDb: BindDb = {
            let bindsDbForKey = bindsDb.filter { $0.key == key.description }
            let sharedBindDb: BindDb? = bindsDbForKey.first { $0.workspaceId == nil }
            guard let workspaceId: UUID = MenuBarManager.instance.workspaceDb?.id else {
                return sharedBindDb
            }
            let workspaceBindDb: BindDb? = bindsDbForKey.first { $0.workspaceId == workspaceId }
            return workspaceBindDb ?? sharedBindDb
        }() else { return }
        
        if bindDb.substring.isEmpty {
            WindowsManager.openApplicationByBundle(bindDb.bundle)
            return
        }
        
        if handleSpecial(bindDb: bindDb) {
            return
        }
        
        // Если среди запущенных приложений нет с нужным bundle то запускаем bundle
        if NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier?.lowercased() == bindDb.bundle.lowercased()
        }) == nil {
            WindowsManager.openApplicationByBundle(bindDb.bundle)
            return
        }
        
        do {
            CachedWindow.cleanClosed__slow()
            
            let windows: [CachedWindow] = cachedWindows.map { $0.value }
            guard let window: CachedWindow = windows.first(where: {
                $0.title.lowercased().contains(bindDb.substring.lowercased()) &&
                $0.appBundle == bindDb.bundle
            }) else { return }
            
            try focusAxuiElement(window.axuiElement)
        } catch {
            reportApi("handleRun() error:\(error.localizedDescription)")
        }
    }
}

private func focusAxuiElement(_ axuiElement: AXUIElement) throws {
    try WindowsManager.focusWindow(axuiElement: axuiElement)
    // Fix Corner Case:
    // - bind Telegram app (option + shift + 1),
    // - press cmd + w to close the window,
    // - press option + 1 to open.
    // Telegram's window won't open.
    if try WindowsManager.getFocusedWindowOrNil() == nil {
        WindowsManager.focusActiveApplication()
    }
}

private func handleSpecial(
    bindDb: BindDb,
) -> Bool {
    if bindDb.bundle == BundleIds.Xcode {
        let project = bindDb.substring
        if isFileExists(project) {
            let result = shell("xed", project)
            // No sense to update cachedWindows
            return result == 0
        }
        return false
    }
    
    if BundleIds.isOpenByShellWithNewWindow(bindDb.bundle) {
        let bundle = bindDb.bundle
        let path = bindDb.substring
        if isFileExists(path) {
            
            // При вызове NSWorkspace.shared.openApplication() с createsNewApplicationInstance
            // macOS начинает анимацию запуска приложения в Dock, хотя по факту открывается еще
            // одно окно а не всё приложение. Каждый раз смотреть эти подпрыгивания не охото,
            // по этому если уже есть окно с этим путем - то его запуск.
            CachedWindow.cleanClosed__slow()
            if let cachedProject = cachedWindows.first(
                where: { $0.value.appBundle == bundle && $0.value.shellWithNewWindow == path }
            ) {
                try? focusAxuiElement(cachedProject.value.axuiElement)
                return true
            }
            
            guard let url: URL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle) else {
                return false
            }
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.arguments = [path]
            configuration.createsNewApplicationInstance = true
            NSWorkspace.shared.openApplication(at: url, configuration: configuration, completionHandler: { _, _ in
                // Почему-то у объекта приложения из completionHandler .bundleIdentifier всегда nil,
                // из-за этого .addByAxuiElement() работает неправильно. Ищем в запущенных приложениях.
                guard let nsApp = NSWorkspace.shared.runningApplications.first(where: {
                    $0.bundleIdentifier?.lowercased() == bindDb.bundle.lowercased()
                }) else {
                    reportApi("handleSpecial() no app: \(bindDb.bundle)")
                    return
                }
                if let focused = try? WindowsManager.getFocusedWindowOrNil(),
                   let pid = try? focused.pid(),
                   nsApp.processIdentifier == pid {
                    _ = try? CachedWindow.addByAxuiElement(
                        nsRunningApplication: nsApp,
                        axuiElement: focused,
                        shellWithNewWindow: path,
                    )
                }
            })
            return true
        }
        return false
    }
    
    if isFileExists(bindDb.substring) {
        let result = shell("open", "-b", bindDb.bundle, bindDb.substring)
        // No sense to update cachedWindows
        return result == 0
    }
    
    return false
}

private func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}
