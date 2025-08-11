import AppKit
import HotKey

// todo rename to HotKeysUtils

private var numberKeys: [Key: [UUID? /* Workspace id or shared */: AXUIElement?]] = [
    .one: [:], .two: [:], .three: [:], .four: [:], .five: [:],
    .six: [:], .seven: [:], .eight: [:], .nine: [:], .zero: [:],
]

private var keepHotKeyHandlers: [Any] = []

func setupHotKeys() {
    numberKeys.forEach { key, axui in
        
        keepHotKeyHandlers.append(
            HotKey(
                key: key,
                modifiers: [.option, .shift],
                keyDownHandler: {
                    _ = isAccessibilityGranted(showDialog: true)
                    do {
                        let workspaceDb = MenuManager.workspaceDb
                        numberKeys[key]![workspaceDb?.id] = try WindowsManager.getFocusedWindowOrNil()
                        print("pin \(try WindowsManager.getFocusedWindowOrNil()?.id())")
                    } catch {
                        reportApi("getFocusedWindowOrNil() error:\(error)")
                    }
                }
            )
        )
        
        keepHotKeyHandlers.append(
            HotKey(
                key: key,
                modifiers: [.option],
                keyDownHandler: {
                    Task { @MainActor in
                        handleRun(key: key)
                    }
                }
            )
        )
    }
}

@MainActor
private func handleRun(key: Key) {
    print("handleRun() \(key)")
    _ = isAccessibilityGranted(showDialog: true)
    
    let bindsDb = BindDb.getAll()
    
    guard let bindDb: BindDb = {
        let bindsDbForKey = bindsDb.filter { $0.key == key.description }
        let sharedBindDb: BindDb? = bindsDbForKey.first { $0.workspaceId == nil }
        guard let workspaceId: UUID = MenuManager.workspaceDb?.id else {
            return sharedBindDb
        }
        let workspaceBindDb: BindDb? = bindsDbForKey.first { $0.workspaceId == workspaceId }
        return workspaceBindDb ?? sharedBindDb
    }() else { return }
    
    if bindDb.substring.isEmpty {
        WindowsManager.openApplicationByBundle(bindDb.bundle)
        return
    }
    
    guard let runningApplication = NSWorkspace.shared.runningApplications.first(where: {
        $0.bundleIdentifier?.lowercased() == bindDb.bundle.lowercased()
    }) else {
        WindowsManager.openApplicationByBundle(bindDb.bundle)
        return
    }
    
    // todo do catch
    let pid = runningApplication.processIdentifier
    let axElement = AXUIElementCreateApplication(pid)
    let windows = try! axElement.allWindows(pid)
    
    guard let window = windows.first(where: {
        try! $0.title()!.lowercased().contains(bindDb.substring.lowercased())
    }) else { return }
    
    try! WindowsManager.focusWindow(axuiElement: window)
    // Fix Corner Case:
    // - bind Telegram app (option + shift + 1),
    // - press cmd + w to close the window,
    // - press option + 1 to open.
    // Telegram's window won't open.
    if try! WindowsManager.getFocusedWindowOrNil() == nil {
        WindowsManager.focusActiveApplication()
    }
    
    /*
    let workspaceAxui: AXUIElement? = numberKeys[key]![MenuManager.workspaceDb?.id] ?? nil
    let sharedAxui: AXUIElement? = numberKeys[key]![nil] ?? nil
    if let axui = (workspaceAxui ?? sharedAxui) {
        do {
            try WindowsManager.focusWindow(axuiElement: axui)
            // Fix Corner Case:
            // - bind Telegram app (option + shift + 1),
            // - press cmd + w to close the window,
            // - press option + 1 to open.
            // Telegram's window won't open.
            if try WindowsManager.getFocusedWindowOrNil() == nil {
                WindowsManager.focusActiveApplication()
            }
        } catch {
            reportApi("focusWindow() error:\(error)")
        }
    }
    */
}
