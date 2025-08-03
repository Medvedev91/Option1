//
// Create Image Example
//
// var checkMark = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Checked")!
// let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold, scale: .small)
// checkMark = checkMark.withSymbolConfiguration(config)!
//

import AppKit

private let statusBar: NSStatusBar = NSStatusBar.system
private let statusItem: NSStatusItem = statusBar.statusItem(
    withLength: NSStatusItem.variableLength
)
private let statusMenu = NSMenu(title: "Option 1")

class MenuManager {
    
    static func setup() {
        // todo title
        statusItem.button?.title = "Shared"
        statusItem.menu = statusMenu
        
        // todo
        let i1 = statusMenu.addItem(
            withTitle: "Shared",
            // todo
            action: #selector(AppDelegate.openSettings),
            keyEquivalent: ""
        )
        // todo
        i1.state = .on
        
        statusMenu.addItem(NSMenuItem.separator())
        
        statusMenu.addItem(
            withTitle: "Settings             ", // Spaces to extra menu width
            action: #selector(AppDelegate.openSettings),
            keyEquivalent: ""
        )
    }
}

private extension AppDelegate {
    
    @objc func openSettings() {
        // todo
        print("openSettings")
    }
}
