import Cocoa

private var myWindowId = CGWindowID(0)

struct WindowsManager {
    
    static func getWindowsForActiveApplicationOrNil() throws -> [AXUIElement]? {
        guard let app = getActiveApplicationOrNil() else { return nil }
        let pid = app.processIdentifier
        let axuiElement = AXUIElementCreateApplication(pid)
        return try axuiElement.allWindows(pid)
    }
    
    static func getFocusedWindowOrNil() throws -> AXUIElement? {
        guard let app = getActiveApplicationOrNil() else { return nil }
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
    
    static func focusActiveApplication() {
        // Based on https://stackoverflow.com/a/58241536
        guard let app: NSRunningApplication = getActiveApplicationOrNil(),
              let bundle: String = app.bundleIdentifier
        else { return }
        openApplicationByBundle(bundle)
    }
    
    static func openApplicationByBundle(
        _ bundle: String,
        arguments: [String] = [],
    ) {
        guard let url: URL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle) else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.arguments = arguments
        NSWorkspace.shared.openApplication(at: url, configuration: configuration, completionHandler: nil)
    }
    
    static func getActiveApplicationOrNil() -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first { $0.isActive }
    }
}

// Source https://github.com/lwouis/alt-tab-macos/blob/b325cc75c02ea6685e9adef93e49a8a1700062fb/src/logic/Window.swift#L198
private func makeKeyWindow(_ psn: inout ProcessSerialNumber) -> Void {
    var bytes = [UInt8](repeating: 0, count: 0xf8)
    bytes[0x04] = 0xf8
    bytes[0x3a] = 0x10
    memcpy(&bytes[0x3c], &myWindowId, MemoryLayout<UInt32>.size)
    memset(&bytes[0x20], 0xff, 0x10)
    bytes[0x08] = 0x01
    SLPSPostEventRecordTo(&psn, &bytes)
    bytes[0x08] = 0x02
    SLPSPostEventRecordTo(&psn, &bytes)
}
