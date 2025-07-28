import AppKit
import HotKey

private var numberKeys: [Key: AXUIElement?] = [
    .one: nil, .two: nil, .three: nil, .four: nil, .five: nil,
    .six: nil, .seven: nil, .eight: nil, .nine: nil, .zero: nil,
]

private var keepKeys: [Any] = []

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        numberKeys.forEach { key, axui in
            keepKeys.append(
                HotKey(
                    key: key,
                    modifiers: [.option, .shift],
                    keyDownHandler: {
                        do {
                            numberKeys[key] = try WindowsManager.getFocusedWindowOrNil()
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
                        if let axui = numberKeys[key], let axui = axui {
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
}
