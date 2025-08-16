import AppKit
import HotKey

// todo rename to HotKeysUtils

private let keys: [Key] = [.one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .zero]

private var keepHotKeyHandlers: [Any] = []

func setupHotKeys() {
    keys.forEach { key in
        keepHotKeyHandlers.append(
            HotKey(
                key: key,
                modifiers: [.option],
                keyDownHandler: {
                    Task { @MainActor in
                        handleRun(key: key)
                    }
                },
            )
        )
    }
}

@MainActor
private func handleRun(key: Key) {
    _ = isAccessibilityGranted(showDialog: true)
    
    let bindsDb = BindDb.selectAll()
    
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
    
    let pid = runningApplication.processIdentifier
    let axElement = AXUIElementCreateApplication(pid)
    
    do {
        let windows = try axElement.allWindows(pid)
        
        guard let window = try windows.first(where: {
            try $0.title()!.lowercased().contains(bindDb.substring.lowercased())
        }) else { return }
        
        try WindowsManager.focusWindow(axuiElement: window)
        // Fix Corner Case:
        // - bind Telegram app (option + shift + 1),
        // - press cmd + w to close the window,
        // - press option + 1 to open.
        // Telegram's window won't open.
        if try WindowsManager.getFocusedWindowOrNil() == nil {
            WindowsManager.focusActiveApplication()
        }
    } catch {
        reportApi("handleRun() error:\(error.localizedDescription)")
    }
}
