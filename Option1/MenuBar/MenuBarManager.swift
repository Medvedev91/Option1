//
// Create Image Example
//
// var checkMark = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Checked")!
// let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold, scale: .small)
// checkMark = checkMark.withSymbolConfiguration(config)!
//

import AppKit
import HotKey

private let statusBar: NSStatusBar = NSStatusBar.system
private let statusItem: NSStatusItem = statusBar.statusItem(
    withLength: NSStatusItem.variableLength
)
private let statusMenu = NSMenu(title: "Option1")

class MenuBarManager: ObservableObject {
    
    static let instance = MenuBarManager()
    
    @Published var workspaceDb: WorkspaceDb?
    @Published var workspacesDb: [WorkspaceDb] = []
    @Published var bindsDb: [BindDb] = []
    
    var workspacesUi: [MenuBarWorkspaceUi] = []
    
    @MainActor
    func setup() {
        statusItem.menu = statusMenu
        updateUi()
    }
    
    @MainActor
    func setWorkspaceDb(_ workspaceDb: WorkspaceDb?) {
        self.workspaceDb = workspaceDb
        updateUi()
    }
    
    @MainActor
    func setWorkspacesDb(_ workspacesDb: [WorkspaceDb]) {
        // todo Publishing changes from within view updates is not allowed, this will cause undefined behavior.
        self.workspacesDb = workspacesDb
        if let workspaceDb = self.workspaceDb {
            if !workspacesDb.contains(where: { $0.id == workspaceDb.id }) {
                self.workspaceDb = nil
            }
        }
        updateUi()
    }
    
    @MainActor
    func setBindsDb(_ bindsDb: [BindDb]) {
        // todo Publishing changes from within view updates is not allowed, this will cause undefined behavior.
        self.bindsDb = bindsDb
        updateUi()
    }
    
    ///

    @MainActor
    private func updateUi() {
        syncWorkspacesUi()
        
        //
        // Menu
        
        statusItem.button?.title = workspaceDb?.name ?? "Shared"
        statusMenu.items.removeAll()

        //
        // Workspaces
        
        self.workspacesUi.forEach { workspaceUi in
            let workspaceItem = NSMenuItem(
                title: workspaceUi.workspaceDb?.name ?? "Shared",
                action: #selector(AppDelegate.setWorkspace),
                keyEquivalent: ""
            )
            workspaceItem.state = workspaceUi.isSelected ? .on : .off
            workspaceItem.representedObject = workspaceUi.workspaceDb
            statusMenu.addItem(workspaceItem)
        }
        
        //
        // Binds
        
        statusMenu.addItem(NSMenuItem.separator())
        for key in HotKeysUtils.keys {
            let keyString = key.description
            guard let bindDb: BindDb =
                    bindsDb.first (where: { $0.key == keyString && $0.workspaceId == self.workspaceDb?.id }) ??
                    bindsDb.first(where: { $0.key == keyString && $0.workspaceId == nil }) else {
                continue
            }
            let bindItem = NSMenuItem(
                title: bindDb.selectAppNameOrNil() ?? bindDb.bundle,
                action: #selector(AppDelegate.runHotKey),
                keyEquivalent: ""
            )
            bindItem.representedObject = key
            if !bindDb.substring.isEmpty {
                bindItem.subtitle = userRelativePath(bindDb.substring)
            }
            bindItem.badge = .init(string: "⌥\(keyString)")
            statusMenu.addItem(bindItem)
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
    
    private func syncWorkspacesUi() {
        var workspacesUi: [MenuBarWorkspaceUi] = []
        workspacesUi.append(
            MenuBarWorkspaceUi(
                workspaceDb: nil,
                isSelected: self.workspaceDb == nil,
            )
        )
        for workspaceDb in workspacesDb {
            workspacesUi.append(
                MenuBarWorkspaceUi(
                    workspaceDb: workspaceDb,
                    isSelected: self.workspaceDb?.id == workspaceDb.id,
                )
            )
        }
        self.workspacesUi = workspacesUi
    }
}

private extension AppDelegate {
    
    @objc func openSettings() {
        WindowsManager.openApplicationByBundle(Bundle.main.bundleIdentifier!)
    }
    
    @MainActor
    @objc func setWorkspace(_ menuItem: NSMenuItem) {
        let workspaceDb: WorkspaceDb? = menuItem.representedObject as? WorkspaceDb
        MenuBarManager.instance.setWorkspaceDb(workspaceDb)
    }
    
    @MainActor
    @objc func runHotKey(_ menuItem: NSMenuItem) {
        guard let key: Key = menuItem.representedObject as? Key else {
            return
        }
        HotKeysUtils.handleRun(key: key)
    }
}
