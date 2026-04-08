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
private var optionTabJkHotKeyHandlers: [HotKey] = []
private var optionTabArrowsHotKeyHandlers: [HotKey] = []

private var optionTabFlagsLocalMonitorForEvents: Any?
private var optionTabFlagsGlobalMonitorForEvents: Any?

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
                            handleKey(key: key)
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
                    onOptionTabKeyDownPressed(fromJk: false)
                },
                keyUpHandler: {
                    onOptionTabKeyUpPressed()
                },
            )
        )
        
        optionTabHotKeyHandlers.append(
            HotKey(
                key: .tab,
                modifiers: [.option, .shift],
                keyDownHandler: {
                    onOptionShiftTabKeyDownPressed()
                },
                keyUpHandler: {
                    onOptionShiftTabKeyUpPressed()
                },
            )
        )
        
        optionTabFlagsLocalMonitorForEvents = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event -> NSEvent? in
            if event.modifierFlags.contains(.option) {
                BadgesManager.updateAsync()
            } else {
                onOptionTabKeyUp()
            }
            return event
        }
        // Для отладки производительности открытия Option-Tab удобно использовать этот метод.
        // Суть - быстро нажимать Option-Tab и смотреть разницу между двумя "b1", именно "b1" а не "b2",
        // т.е. между нажатием от отпусканием Option. На момент разработки укладывался в 100млс.
        optionTabFlagsGlobalMonitorForEvents = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            // print(";;; b1 \(timeMls())")
            if event.modifierFlags.contains(.option) {
                BadgesManager.updateAsync()
            } else {
                onOptionTabKeyUp()
                // print(";;; b2 \(timeMls())")
            }
        }
        
        ///
        
        if KvDb.selectOptionTabDbMode() == .jk {
            enableOptionTabJkHotKeys()
        }
    }
    
    static func disableOptionTab() {
        // Hot Keys
        optionTabHotKeyHandlers.forEach { hotKey in
            hotKey.isPaused = true
        }
        optionTabHotKeyHandlers.removeAll()
        // Modifier Events
        if let optionTabFlagsLocalMonitorForEventsLocal = optionTabFlagsLocalMonitorForEvents {
            NSEvent.removeMonitor(optionTabFlagsLocalMonitorForEventsLocal)
            optionTabFlagsLocalMonitorForEvents = nil
        }
        if let optionTabFlagsGlobalMonitorForEventsLocal = optionTabFlagsGlobalMonitorForEvents {
            NSEvent.removeMonitor(optionTabFlagsGlobalMonitorForEventsLocal)
            optionTabFlagsGlobalMonitorForEvents = nil
        }
        // JK
        disableOptionTabJkHotKeys()
    }
    
    @MainActor
    static func enableOptionTabJkHotKeys() {
        // Eliminate duplications
        if !optionTabJkHotKeyHandlers.isEmpty {
            return
        }
        
        optionTabJkHotKeyHandlers.append(
            HotKey(
                key: .j,
                modifiers: [.option],
                keyDownHandler: {
                    onOptionTabKeyDownPressed(fromJk: true)
                },
                keyUpHandler: {
                    onOptionTabKeyUpPressed()
                },
            )
        )
        optionTabJkHotKeyHandlers.append(
            HotKey(
                key: .k,
                modifiers: [.option],
                keyDownHandler: {
                    onOptionShiftTabKeyDownPressed()
                },
                keyUpHandler: {
                    onOptionShiftTabKeyUpPressed()
                },
            )
        )
    }
    
    static func disableOptionTabJkHotKeys() {
        optionTabJkHotKeyHandlers.forEach { hotKey in
            hotKey.isPaused = true
        }
        optionTabJkHotKeyHandlers.removeAll()
    }
    
    @MainActor
    static func enableOptionTabArrowsHotKeys() {
        // Eliminate duplications
        if !optionTabArrowsHotKeyHandlers.isEmpty {
            return
        }
        
        optionTabArrowsHotKeyHandlers.append(
            HotKey(
                key: .downArrow,
                modifiers: [.option],
                keyDownHandler: {
                    onOptionTabKeyDownPressed(fromJk: false)
                },
                keyUpHandler: {
                    onOptionTabKeyUpPressed()
                },
            )
        )
        optionTabArrowsHotKeyHandlers.append(
            HotKey(
                key: .upArrow,
                modifiers: [.option],
                keyDownHandler: {
                    onOptionShiftTabKeyDownPressed()
                },
                keyUpHandler: {
                    onOptionShiftTabKeyUpPressed()
                },
            )
        )
    }
    
    static func disableOptionTabArrowsHotKeys() {
        optionTabArrowsHotKeyHandlers.forEach { hotKey in
            hotKey.isPaused = true
        }
        optionTabArrowsHotKeyHandlers.removeAll()
    }
    
    @MainActor
    static func handleKey(key: Key) {
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
        
        handleRaw(bundle: bindDb.bundle, substring: bindDb.substring)
    }
    
    @MainActor
    static func handleRaw(
        bundle: String,
        substring: String,
    ) {
        if substring.isEmpty {
            WindowsManager.openApplicationByBundle(bundle)
            return
        }
        
        if handleSpecial(bundle: bundle, substring: substring) {
            return
        }
        
        // Если среди запущенных приложений нет с нужным bundle то запускаем bundle
        if NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier?.lowercased() == bundle.lowercased()
        }) == nil {
            WindowsManager.openApplicationByBundle(bundle)
            return
        }
        
        do {
            CachedWindow.cleanClosed__slow()
            
            let windows: [CachedWindow] = cachedWindows.map { $0.value }
            guard let window: CachedWindow = windows.first(where: {
                $0.title.lowercased().contains(substring.lowercased()) &&
                $0.appBundle == bundle
            }) else { return }
            
            try focusAxuiElement(window.axuiElement)
        } catch {
            reportApi("handleRun() error:\(error.localizedDescription)")
        }
    }
}

//
// Option-Tab Handlers

@MainActor
private func onOptionTabKeyDownPressed(fromJk: Bool) {
    OptionTabManager.instance.onOptionTabPressed(fromJk: fromJk)
    onOptionTabPressedTask = Task { @MainActor in
        try await Task.sleep(nanoseconds: onOptionTabLongPressFirstDelay)
        while onOptionTabPressedTask != nil {
            try await Task.sleep(nanoseconds: onOptionTabLongPressRepeatDelay)
            OptionTabManager.instance.onOptionTabPressed(fromJk: fromJk)
        }
    }
}

private func onOptionTabKeyUpPressed() {
    onOptionTabPressedTask?.cancel()
    onOptionTabPressedTask = nil
}

@MainActor
private func onOptionShiftTabKeyDownPressed() {
    OptionTabManager.instance.onOptionShiftTabPressed()
    onOptionShiftTabPressedTask = Task { @MainActor in
        try await Task.sleep(nanoseconds: onOptionTabLongPressFirstDelay)
        while onOptionShiftTabPressedTask != nil {
            try await Task.sleep(nanoseconds: onOptionTabLongPressRepeatDelay)
            OptionTabManager.instance.onOptionShiftTabPressed()
        }
    }
}

private func onOptionShiftTabKeyUpPressed() {
    onOptionShiftTabPressedTask?.cancel()
    onOptionShiftTabPressedTask = nil
}

@MainActor
private func onOptionTabKeyUp() {
    OptionTabManager.instance.onOptionKeyUp()
    onOptionTabKeyUpPressed()
    onOptionShiftTabKeyUpPressed()
}

///

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

@MainActor
private func handleSpecial(
    bundle: String,
    substring: String,
) -> Bool {
    if bundle == BundleIds.Xcode {
        let project = substring
        if isFileExists(project) {
            let result = shell("xed", project)
            // No sense to update cachedWindows
            return result == 0
        }
        return false
    }
    
    if BundleIds.isOpenByShellWithNewWindow(bundle) {
        let path = substring
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
                    $0.bundleIdentifier?.lowercased() == bundle.lowercased()
                }) else {
                    reportApi("handleSpecial() no app: \(bundle)")
                    return
                }
                // todo
                // Борьба с ошибкой, кода после открытия окна с path для
                // shellWithNewWindow, path присваивается другому. Возможно из-за
                // того что getFocusedWindowOrNil() возвращает прежнее окно.
                // Возможно asyncAfter еще сильнее усугубляет ситуацию. Нужно время
                // тестировать т.к. баг плавающий. Начал 2026-04-03.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let focused = try? WindowsManager.getFocusedWindowOrNil(),
                       let pid = try? focused.pid(),
                       nsApp.processIdentifier == pid {
                        try? CachedWindow.addByAxuiElement(
                            nsRunningApplication: nsApp,
                            axuiElement: focused,
                            shellWithNewWindow: path,
                        )
                    }
                }
            })
            return true
        }
        return false
    }
    
    if isFileExists(substring) {
        let result = shell("open", "-b", bundle, substring)
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
