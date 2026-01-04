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
}
