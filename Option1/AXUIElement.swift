import Cocoa
import ApplicationServices.HIServices.AXUIElement
import ApplicationServices.HIServices.AXValue
import ApplicationServices.HIServices.AXError
import ApplicationServices.HIServices.AXRoleConstants
import ApplicationServices.HIServices.AXAttributeConstants
import ApplicationServices.HIServices.AXActionConstants

// Source https://github.com/lwouis/alt-tab-macos/blob/master/src/api-wrappers/AXUIElement.swift

extension AXUIElement {

    func axCallWhichCanThrow<T>(_ result: AXError, _ successValue: inout T) throws -> T? {
        switch result {
            case .success: return successValue
            // .cannotComplete can happen if the app is unresponsive; we throw in that case to retry until the call succeeds
            case .cannotComplete: throw AxError.runtimeError
            // for other errors it's pointless to retry
            default: return nil
        }
    }

    // periphery:ignore
    func id() -> AXUIElementID? {
        let pointer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque()).advanced(by: 0x20)
        let cfDataPointer = pointer.load(as: CFData?.self)
        // Доработка Option1, иначе креш приложения.
        guard let cfData = cfDataPointer else {
            let exTitles = ["loginwindow"]
            let title: String? = try? title()
            if let title = title, exTitles.contains(title) {
                return nil
            }
            reportApi("AXUIElement.id() cfData = nil for \(title ?? "NO TITLE")")
            return nil
        }
        let bytePtr = CFDataGetBytePtr(cfData)
        return bytePtr?.withMemoryRebound(to: AXUIElementID.self, capacity: 1) { $0.pointee }
    }

    func cgWindowId() throws -> CGWindowID? {
        var id = CGWindowID(0)
        return try axCallWhichCanThrow(_AXUIElementGetWindow(self, &id), &id)
    }

    func pid() throws -> pid_t? {
        var pid = pid_t(0)
        return try axCallWhichCanThrow(AXUIElementGetPid(self, &pid), &pid)
    }

    func attribute<T>(_ key: String, _ _: T.Type) throws -> T? {
        var value: AnyObject?
        return try axCallWhichCanThrow(AXUIElementCopyAttributeValue(self, key as CFString, &value), &value) as? T
    }

    func windowAttributes() throws -> (String?, String?, String?, Bool, Bool)? {
        let attributes = [
            kAXTitleAttribute,
            kAXRoleAttribute,
            kAXSubroleAttribute,
            kAXMinimizedAttribute,
            kAXFullscreenAttribute,
        ]
        var values: CFArray?
        if let array = ((try axCallWhichCanThrow(AXUIElementCopyMultipleAttributeValues(self, attributes as CFArray, [], &values), &values)) as? Array<Any>) {
            return (
                array[0] as? String,
                array[1] as? String,
                array[2] as? String,
                // if the value is nil, we return false. This avoid returning Bool?; simplifies things
                (array[3] as? Bool) ?? false,
                // if the value is nil, we return false. This avoid returning Bool?; simplifies things
                (array[4] as? Bool) ?? false
            )
        }
        return nil
    }

    private func value<T>(_ key: String, _ target: T, _ type: AXValueType) throws -> T? {
        if let a = try attribute(key, AXValue.self) {
            var value = target
            _ = withUnsafePointer(to: &value) {
                AXValueGetValue(a, type, UnsafeMutableRawPointer(mutating: $0))
            }
            return value
        }
        return nil
    }

    func title() throws -> String? {
        return try attribute(kAXTitleAttribute, String.self)
    }

    // periphery:ignore
    func parent() throws -> AXUIElement? {
        return try attribute(kAXParentAttribute, AXUIElement.self)
    }

    func children() throws -> [AXUIElement]? {
        return try attribute(kAXChildrenAttribute, [AXUIElement].self)
    }

    func isMinimized() throws -> Bool {
        // if the AX call doesn't return, we return false. This avoid returning Bool?; simplifies things
        return try attribute(kAXMinimizedAttribute, Bool.self) == true
    }

    func isFullscreen() throws -> Bool {
        // if the AX call doesn't return, we return false. This avoid returning Bool?; simplifies things
        return try attribute(kAXFullscreenAttribute, Bool.self) == true
    }

    func focusedWindow() throws -> AXUIElement? {
        return try attribute(kAXFocusedWindowAttribute, AXUIElement.self)
    }

    func role() throws -> String? {
        return try attribute(kAXRoleAttribute, String.self)
    }

    func subrole() throws -> String? {
        return try attribute(kAXSubroleAttribute, String.self)
    }

    func closeButton() throws -> AXUIElement? {
        return try attribute(kAXCloseButtonAttribute, AXUIElement.self)
    }

    func appIsRunning() throws -> Bool? {
        return try attribute(kAXIsApplicationRunningAttribute, Bool.self)
    }

    /// doesn't return windows on other Spaces
    /// use windowsByBruteForce if you want those
    func windows() throws -> [AXUIElement] {
        let windows = try attribute(kAXWindowsAttribute, [AXUIElement].self)
        if let windows,
           !windows.isEmpty {
            // bug in macOS: sometimes the OS returns multiple duplicate windows (e.g. Mail.app starting at login)
            let uniqueWindows = Array(Set(windows))
            if !uniqueWindows.isEmpty {
                return uniqueWindows
            }
        }
        return []
    }

    func position() throws -> CGPoint? {
        return try value(kAXPositionAttribute, CGPoint.zero, .cgPoint)
    }

    func size() throws -> CGSize? {
        return try value(kAXSizeAttribute, CGSize.zero, .cgSize)
    }
    
    // Option 1 Implementation
    func isElementExists() -> Bool {
        guard let subrole = try? subrole() else {
            return false
        }
        // Подсмотрено в методе windowsByBruteForce()
        return [kAXStandardWindowSubrole, kAXDialogSubrole].contains(subrole)
    }

    /// Внимание! Очень медленная функция!
    /// we combine both the normal approach and brute-force to get all possible windows
    /// with only normal approach: we miss other-Spaces windows
    /// with only brute-force approach: we miss windows when the app launches (e.g. launch Note.app: first window is not found by brute-force)
    func allWindows(_ pid: pid_t) throws -> [AXUIElement] {
        let aWindows = try windows()
        let bWindows = AXUIElement.windowsByBruteForce(pid)
        return Array(Set(aWindows + bWindows))
    }

    /// Внимание! Очень медленная функция!
    /// brute-force getting the windows of a process by iterating over AXUIElementID one by one
    private static func windowsByBruteForce(_ pid: pid_t) -> [AXUIElement] {
        // we use this to call _AXUIElementCreateWithRemoteToken; we reuse the object for performance
        // tests showed that this remoteToken is 20 bytes: 4 + 4 + 4 + 8; the order of bytes matters
        var remoteToken = Data(count: 20)
        remoteToken.replaceSubrange(0..<4, with: withUnsafeBytes(of: pid) { Data($0) })
        remoteToken.replaceSubrange(4..<8, with: withUnsafeBytes(of: Int32(0)) { Data($0) })
        remoteToken.replaceSubrange(8..<12, with: withUnsafeBytes(of: Int32(0x636f636f)) { Data($0) })
        var axWindows = [AXUIElement]()
        // we iterate to 1000 as a tradeoff between performance, and missing windows of long-lived processes
        // Увеличил до 6000. Мой максимальный PID 5187.
        for axUiElementId: AXUIElementID in 0..<6_000 {
            remoteToken.replaceSubrange(12..<20, with: withUnsafeBytes(of: axUiElementId) { Data($0) })
            if let axUiElement = _AXUIElementCreateWithRemoteToken(remoteToken as CFData)?.takeRetainedValue(),
               let subrole = try? axUiElement.subrole(),
               [kAXStandardWindowSubrole, kAXDialogSubrole].contains(subrole) {
                axWindows.append(axUiElement)
            }
        }
        return axWindows
    }

    func focusWindow() {
        performAction(kAXRaiseAction)
    }

    func setAttribute(_ key: String, _ value: Any) {
        AXUIElementSetAttributeValue(self, key as CFString, value as CFTypeRef)
    }

    func performAction(_ action: String) {
        AXUIElementPerformAction(self, action as CFString)
    }

    func subscribeToNotification(_ axObserver: AXObserver, _ notification: String, _ callback: (() -> Void)? = nil) throws {
        let result = AXObserverAddNotification(axObserver, self, notification as CFString, nil)
        if result == .success || result == .notificationAlreadyRegistered {
            callback?()
        } else if result != .notificationUnsupported && result != .notImplemented {
            throw AxError.runtimeError
        }
    }
}

enum AxError: Error {
    case runtimeError
}

/// tests have shown that this ID has a range going from 0 to probably UInt.MAX
/// it starts at 0 for each app, and increments over time, for each new UI element
/// this means that long-lived apps (e.g. Finder) may have high IDs
/// we don't know how high it can go, and if it wraps around
typealias AXUIElementID = UInt64
