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
private var statusItem: NSStatusItem?
private let statusMenu = NSMenu(title: "Option1")

@MainActor
class MenuBarManager: ObservableObject {
    
    static let instance = MenuBarManager()
    
    var isEnabled: Bool = KvDb.selectIsDisplayInMenuBar()
    
    @Published var workspaceDb: WorkspaceDb?
    @Published var workspacesDb: [WorkspaceDb] = []
    @Published var bindsDb: [BindDb] = []
    
    var workspacesUi: [MenuBarWorkspaceUi] = []
    var bindsUi: [MenuBarBindUi] = []
    
    func setup() {
        updateUi()
    }
    
    func setWorkspaceDb(_ workspaceDb: WorkspaceDb?) {
        self.workspaceDb = workspaceDb
        updateUi()
    }
    
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
    
    func setBindsDb(_ bindsDb: [BindDb]) {
        // todo Publishing changes from within view updates is not allowed, this will cause undefined behavior.
        self.bindsDb = bindsDb
        updateUi()
    }
    
    func setIsEnabled(_ isEnabled: Bool) {
        self.isEnabled = isEnabled
        KvDb.upsertIsDisplayInMenuBar(isEnabled)
        updateUi()
    }
    
    ///

    private func updateUi() {
        
        // Обязательно запускать т.к. данные
        // используются в т.ч. в Option-Tab.
        syncWorkspacesUi()
        syncBindsUi()
        
        if !isEnabled {
            if let statusItemLocal = statusItem {
                statusBar.removeStatusItem(statusItemLocal)
            }
            statusItem = nil
            return
        }
        let statusItemLocal = statusItem ?? statusBar.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = statusItemLocal
        statusItemLocal.menu = statusMenu
        
        //
        // Menu
        
        statusItemLocal.button?.title = workspaceDb?.name ?? "Shared"
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
        bindsUi.forEach { bindUi in
            let bindItem = NSMenuItem(
                title: bindUi.title,
                action: #selector(AppDelegate.runHotKey),
                keyEquivalent: ""
            )
            bindItem.representedObject = bindUi.key
            bindItem.subtitle = bindUi.subtitle
            bindItem.badge = .init(string: bindUi.badge)
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
    
    private func syncBindsUi() {
        var bindsUi: [MenuBarBindUi] = []
        for key in HotKeysUtils.keys {
            let keyString = key.description
            guard let bindDb: BindDb =
                    bindsDb.first (where: { $0.key == keyString && $0.workspaceId == self.workspaceDb?.id }) ??
                    bindsDb.first(where: { $0.key == keyString && $0.workspaceId == nil }) else {
                continue
            }
            bindsUi.append(
                MenuBarBindUi(
                    bindDb: bindDb,
                    title: bindDb.selectAppNameOrNil() ?? bindDb.bundle,
                    subtitle: bindDb.substring.isEmpty ? nil : userRelativePath(bindDb.substring),
                    key: key,
                    badge: "⌥\(keyString)",
                )
            )
        }
        self.bindsUi = bindsUi
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
