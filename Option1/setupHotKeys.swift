import AppKit
import HotKey

private var numberKeys: [Key: [UUID? /* Workspace id or shared */: AXUIElement?]] = [
    .one: [:], .two: [:], .three: [:], .four: [:], .five: [:],
    .six: [:], .seven: [:], .eight: [:], .nine: [:], .zero: [:],
]

private var keepKeys: [Any] = []

func setupHotKeys() {
    numberKeys.forEach { key, axui in
        
        keepKeys.append(
            HotKey(
                key: key,
                modifiers: [.option, .shift],
                keyDownHandler: {
                    _ = isAccessibilityGranted(showDialog: true)
                    do {
                        let workspaceDb = MenuManager.workspaceDb
                        numberKeys[key]![workspaceDb?.id] = try WindowsManager.getFocusedWindowOrNil()
                    } catch {
                        reportApi("getFocusedWindowOrNil() error:\(error)")
                    }
                }
            )
        )
        
        keepKeys.append(
            HotKey(
                key: key,
                modifiers: [.option],
                keyDownHandler: {
                    _ = isAccessibilityGranted(showDialog: true)
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
                }
            )
        )
    }
}
