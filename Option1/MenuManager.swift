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

class MenuManager: ObservableObject {
    
    static let instance = MenuManager()
    
    @Published var workspaceDb: WorkspaceDb?
    @Published var workspacesDb: [WorkspaceDb] = []
    
    func setup() {
        statusItem.menu = statusMenu
        updateUi()
    }
    
    func setWorkspaceDb(_ workspaceDb: WorkspaceDb?) {
        self.workspaceDb = workspaceDb
        updateUi()
    }
    
    func setWorkspacesDb(_ workspacesDb: [WorkspaceDb]) {
        self.workspacesDb = workspacesDb
        if let workspaceDb = self.workspaceDb {
            if !workspacesDb.contains(where: { $0.id == workspaceDb.id }) {
                self.workspaceDb = nil
            }
        }
        updateUi()
    }
    
    ///

    private func updateUi() {
        
        //
        // Menu
        
        statusItem.button?.title = workspaceDb?.name ?? "Shared"
        
        //
        // Items
        
        statusMenu.items.removeAll()
        
        let sharedItem = statusMenu.addItem(
            withTitle: "Shared",
            action: #selector(AppDelegate.setWorkspace),
            keyEquivalent: ""
        )
        if workspaceDb == nil {
            sharedItem.state = .on
        }

        for workspaceDb in workspacesDb {
            let workspaceItem = NSMenuItem(
                title: workspaceDb.name,
                action: #selector(AppDelegate.setWorkspace),
                keyEquivalent: ""
            )
            workspaceItem.representedObject = workspaceDb
            statusMenu.addItem(workspaceItem)
            if self.workspaceDb?.id == workspaceDb.id {
                workspaceItem.state = .on
            }
        }
        
        //
        // Settings
        
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
        WindowsManager.openApplicationByBundle(Bundle.main.bundleIdentifier!)
    }
    
    @objc func setWorkspace(_ menuItem: NSMenuItem) {
        let workspaceDb: WorkspaceDb? = menuItem.representedObject as? WorkspaceDb
        MenuManager.instance.setWorkspaceDb(workspaceDb)
    }
}
