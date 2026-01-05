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
        cleanClosed()
    }
    
    // ВНИМАНИЕ! SUPER SLOW `.allWindows()`
    static func addByApp(_ app: NSRunningApplication) throws {
        let pid = app.processIdentifier
        try AXUIElementCreateApplication(pid).allWindows(pid).forEach { axuiElement in
            try CachedWindow.addByAxuiElement(nsRunningApplication: app, axuiElement: axuiElement)
        }
    }
    
    static func cleanClosed() {
        cachedWindows.forEach { hashValue, cachedWindow in
            let isExists: Bool = AXUIElement.isElementIdExists(
                pid: cachedWindow.pid,
                axuiElementId: cachedWindow.axuiElementId,
            )
            if !isExists {
                cachedWindows.removeValue(forKey: hashValue)
            }
        }
    }
    
    static func cleanByBundle(_ bundle: String) {
        cachedWindows
            .filter { $0.value.appBundle == bundle }
            .forEach { hashValue, d in
                cachedWindows.removeValue(forKey: hashValue)
            }
    }
}
