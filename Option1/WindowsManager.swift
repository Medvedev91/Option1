import Cocoa

struct WindowsManager {
    
    static func getFocusedWindowOrNil() throws -> AXUIElement? {
        guard let app = getActiveApplication() else { return nil }
        return try AXUIElementCreateApplication(app.processIdentifier).focusedWindow()
    }
    
    static func focusWindow(axuiElement: AXUIElement) throws {
        var psn = ProcessSerialNumber()
        guard let pid = try axuiElement.pid() else {
            throw AppError.simple("WindowsManager: no pid")
        }
        GetProcessForPID(pid, &psn)
        _SLPSSetFrontProcessWithOptions(&psn, myWindowId, SLPSMode.userGenerated.rawValue)
        makeKeyWindow(&psn)
        axuiElement.focusWindow()
    }
}

private func getActiveApplication() -> NSRunningApplication? {
    NSWorkspace.shared.runningApplications.first(where: { $0.isActive })
}
