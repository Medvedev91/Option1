import AppKit

var cachedWindows: [Int: CachedWindow] = [:]

struct CachedWindow {
    
    let axuiElement: AXUIElement
    let pid: pid_t
    let axuiElementId: AXUIElementID
    let title: String
    let appBundle: String
    
    static func addByAxuiElement(
        nsRunningApplication: NSRunningApplication,
        axuiElement: AXUIElement
    ) throws {
        if
            let pid = try axuiElement.pid(),
            let axuiElementId = axuiElement.id(),
            let title = try axuiElement.title(),
            let bundleIdentifier = nsRunningApplication.bundleIdentifier {
            cachedWindows[axuiElement.hashValue] = CachedWindow(
                axuiElement: axuiElement,
                pid: pid,
                axuiElementId: axuiElementId,
                title: title,
                appBundle: bundleIdentifier
            )
        }
    }
    
    // ВНИМАНИЕ! SUPER SLOW `.allWindows()`
    static func addByApp(_ app: NSRunningApplication) throws {
        let pid = app.processIdentifier
        try AXUIElementCreateApplication(pid).allWindows(pid).forEach { axuiElement in
            try CachedWindow.addByAxuiElement(nsRunningApplication: app, axuiElement: axuiElement)
        }
    }
    
    //
    // Внимание 1
    // Вызов функции занимает время хоть и не много: 2-50млс,
    // не желательно вызывать в критичных местах.
    //
    // Внимание 2
    // Нельзя вызывать данную функцию например после перехода macOS
    // в режим сна, в таком случае она удалит вообще все окна, хотя
    // по факту они сохранятся после пробуждения.
    // todo обдумать проверку выхода из учетки через начилие Finder.
    //
    static func cleanClosed() {
        cachedWindows
            .filter { _, cachedWindow in
                !cachedWindow.axuiElement.isElementExists()
            }
            .forEach { hashValue, cachedWindow in
                cachedWindows.removeValue(forKey: hashValue)
            }
    }
    
    static func cleanByBundle(_ bundle: String) {
        cachedWindows
            .filter { $0.value.appBundle == bundle }
            .forEach { hashValue, _ in
                cachedWindows.removeValue(forKey: hashValue)
            }
    }
}
