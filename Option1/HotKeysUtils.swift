import AppKit
import HotKey

private var keepHotKeyHandlers: [Any] = []

class HotKeysUtils {
    
    static let keys: [Key] = [.one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .zero]

    static func setup() {
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
}

@MainActor
private func handleRun(key: Key) {
    _ = isAccessibilityGranted(showDialog: true)
    
    let bindsDb = BindDb.selectAll()
    
    guard let bindDb: BindDb = {
        let bindsDbForKey = bindsDb.filter { $0.key == key.description }
        let sharedBindDb: BindDb? = bindsDbForKey.first { $0.workspaceId == nil }
        guard let workspaceId: UUID = MenuManager.instance.workspaceDb?.id else {
            return sharedBindDb
        }
        let workspaceBindDb: BindDb? = bindsDbForKey.first { $0.workspaceId == workspaceId }
        return workspaceBindDb ?? sharedBindDb
    }() else { return }
    
    if bindDb.substring.isEmpty {
        WindowsManager.openApplicationByBundle(bindDb.bundle)
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
        // Т.к. cleanClosed() занимает время, нужно ее использовать только
        // когда важен ее результат, т.е. перед использованием cachedWindows.
        // todo Проверять скорость работы и репортить если ниже 100мс.
        CachedWindow.cleanClosed()

        let windows: [CachedWindow] = cachedWindows.map { $0.value }
        guard let window: CachedWindow = windows.first(where: {
            $0.title.lowercased().contains(bindDb.substring.lowercased()) &&
            $0.appBundle == bindDb.bundle
        }) else { return }

        try WindowsManager.focusWindow(axuiElement: window.axuiElement)
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
