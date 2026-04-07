import AppKit
import Combine
import HotKey

// Without Vim's jk
private let jumpKeys: [Key] = [
    // Letters
    .a, .b, .c, .d, .e, .f, .g, .h, .i, /*.j, .k,*/ .l, .m, .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z,
    // Symbols
    .leftBracket, .rightBracket, .backslash, .semicolon, .quote, .comma, .period, .slash, .grave, .minus, .equal,
]

private var hotKeysJumpHandlers: [HotKey] = []

@MainActor
class OptionTabData: ObservableObject {
    
    @Published var uiMode: OptionTabUiMode
    let onCachedWindowFocus: (CachedWindow) -> Void
    let closeWindow: () -> Void

    @Published var appsUi: [OptionTabAppUi] = []
    @Published var history: [CachedWindow] = []
    @Published var selectedCachedWindow: CachedWindow? = nil
    @Published var favoritesUi: [OptionTabFavoriteUi] = []
    var animateWindowResize = true
    
    @Published var workspacesUi: [OptionTabWorkspaceUi] = []
    @Published var bindsUi: [MenuBarBindUi] = []
    
    @Published var jumpCachedWindowKeyMap: [/* Hash */ Int: Key] = [:]
    
    var windowSize: OptionTabWindowSize {
        let windowsHeight: CGFloat = {
            switch uiMode {
            case .apps:
                let headersHeight: CGFloat = Double(appsUi.count) * OptionTabView.itemHeaderPadding
                let itemsHeight: CGFloat = Double(appsUi.flatMap(\.cachedWindows).count) * OptionTabView.itemHeight
                let bottomPadding = OptionTabView.itemHeaderPadding
                return headersHeight + itemsHeight + bottomPadding
            case .history:
                let headerHeight: CGFloat = OptionTabView.itemHeaderPadding
                let itemsHeight: CGFloat = Double(history.count) * OptionTabView.itemHeight
                let bottomPadding: CGFloat = OptionTabView.itemHeaderPadding
                return headerHeight + itemsHeight + bottomPadding
            }
        }()
        
        let menuHeight: CGFloat = {
            let separators: CGFloat = OptionTabView.menuDividerHeight * 4.0
            let favorites: CGFloat = (OptionTabView.itemHeight * Double(favoritesUi.count)) + OptionTabView.itemHeight
            let vPaddings: CGFloat = OptionTabView.itemHeaderPadding * 2.0
            let systemButtonsHeight: CGFloat = OptionTabView.itemHeight * 2.0 // Settings, Modes.
            let workspacesHeight: CGFloat = Double(workspacesUi.count) * OptionTabView.itemHeight
            let bindsHeight: CGFloat = bindsUi.map { bindUi in
                bindUi.subtitle == nil ? OptionTabView.itemHeight : OptionTabView.itemTwoLinesHeight
            }.reduce(0, +)
            return separators + vPaddings + systemButtonsHeight + workspacesHeight + bindsHeight + favorites
        }()
        
        let contentWidth: CGFloat = OptionTabView.fullWidth
        let contentHeight: CGFloat = max(windowsHeight, menuHeight)
        
        guard let nsScreen: NSScreen = NSScreen.main else {
            return OptionTabWindowSize(
                nsRect: NSRect(x: 0, y: 0, width: contentWidth, height: contentHeight),
                isFullHeight: false,
                safeAreaTop: 0,
            )
        }
        
        let screenWidth: CGFloat = nsScreen.frame.width
        let x: CGFloat = (screenWidth - contentWidth) / 2.0
        
        let screenHeight: CGFloat = nsScreen.frame.height
        let safeAreaTop: CGFloat = nsScreen.safeAreaInsets.top
        
        // Если высота Option-Tab больше высоты экрана
        if contentHeight >= screenHeight {
            return OptionTabWindowSize(
                nsRect: NSRect(x: x, y: 0, width: contentWidth, height: screenHeight),
                isFullHeight: true,
                safeAreaTop: safeAreaTop,
            )
        }

        // Если можно расположить между top safe area и dock
        let screenVisibleHeight: CGFloat = nsScreen.visibleFrame.height
        if screenVisibleHeight >= contentHeight {
            let offsetY: CGFloat = screenVisibleHeight - contentHeight
            let dockHeight: CGFloat = screenHeight - screenVisibleHeight - safeAreaTop
            // dockHeight > 10 т.к. почему-то даже без Dock он равен 1.0. Берем с запасом.
            let offsetBottom: CGFloat = dockHeight + (offsetY / (dockHeight > 10 ? 2 : 1.62))
            return OptionTabWindowSize(
                nsRect: NSRect(x: x, y: offsetBottom, width: contentWidth, height: contentHeight),
                isFullHeight: false,
                safeAreaTop: 0,
            )
        }
        
        let safeScreenHeight: CGFloat = screenHeight - safeAreaTop
        
        // Если можно поместить под top safe area но над dock.
        if safeScreenHeight > contentHeight {
            let offsetY: CGFloat = safeScreenHeight - contentHeight
            let offsetBottom: CGFloat = (offsetY > 4 ? offsetY - 4 : offsetY)
            return OptionTabWindowSize(
                nsRect: NSRect(x: x, y: offsetBottom, width: contentWidth, height: contentHeight),
                isFullHeight: false,
                safeAreaTop: 0,
            )
        }
        
        // Не помещается под safe area, отображаем во весь экран
        return OptionTabWindowSize(
            nsRect: NSRect(x: x, y: 0, width: contentWidth, height: screenHeight),
            isFullHeight: true,
            safeAreaTop: safeAreaTop,
        )
    }
    
    init(
        uiMode: OptionTabUiMode,
        onCachedWindowFocus: @escaping (CachedWindow) -> Void,
        closeWindow: @escaping () -> Void,
    ) {
        self.uiMode = uiMode
        self.onCachedWindowFocus = onCachedWindowFocus
        self.closeWindow = closeWindow

        Publishers.Map(upstream: MenuBarManager.instance.$workspacesUi, transform: { menuBarWorkspacesUi in
            menuBarWorkspacesUi.enumerated().map { (idx, menuBarWorkspaceUi) in
                OptionTabWorkspaceUi(key: jumpKeys[idx], menuBarWorkspaceUi: menuBarWorkspaceUi, onClick: {
                    MenuBarManager.instance.setWorkspaceDb(menuBarWorkspaceUi.workspaceDb)
                })
            }
        }).assign(to: &$workspacesUi)
        
        Publishers.Map(upstream: MenuBarManager.instance.$bindsUi, transform: { $0 }).assign(to: &$bindsUi)
    }
    
    // ВНИМАНИЕ!
    // Строго контролировать скорость выполнения,
    // на момент разработки это ~10млс.
    func rebuild(
        uiMode: OptionTabUiMode,
    ) {
        self.uiMode = uiMode
        self.appsUi = buildAppsUi()
        let history = buildHistory()
        self.history = history
        
        self.selectedCachedWindow = {
            if history.count >= 2 {
                return history[1]
            }
            if history.count == 1 {
                return history[0]
            }
            return nil
        }()
        
        let favoriteExtraIdx = workspacesUi.count
        self.favoritesUi = FavoriteDb.selectAllSorted().enumerated().map { (idx, favoriteDb) in
            OptionTabFavoriteUi(key: jumpKeys[idx + favoriteExtraIdx], favoriteDb: favoriteDb, onClick: {
                self.closeWindow()
                HotKeysUtils.handleRaw(
                    bundle: favoriteDb.bundle,
                    substring: favoriteDb.substring,
                )
            })
        }
        
        let windowsExtraIdx = favoriteExtraIdx + favoritesUi.count
        // Не использую Set т.к. важен порядок
        let busyKeys = jumpKeys[0..<windowsExtraIdx]
        var freeKeys = jumpKeys[windowsExtraIdx..<jumpKeys.count]
        // Освобождаем клавиши если были добавлены рабочие пространства или избранные
        jumpCachedWindowKeyMap.forEach { (hash, key) in
            if busyKeys.contains(key) {
                jumpCachedWindowKeyMap.removeValue(forKey: hash)
            }
        }
        // Освобождаем клавиши для закрытых окон
        // Не использую Set т.к. важен порядок
        let windowsHashes = history.map(\.axuiElement.hashValue)
        jumpCachedWindowKeyMap.forEach { (hash, key) in
            if !windowsHashes.contains(hash) {
                jumpCachedWindowKeyMap.removeValue(forKey: hash)
            } else {
                freeKeys.removeAll { $0 == key }
            }
        }
        windowsHashes.forEach { hash in
            if freeKeys.isEmpty {
                return
            }
            if jumpCachedWindowKeyMap[hash] == nil {
                jumpCachedWindowKeyMap[hash] = freeKeys.popFirst()!
            }
        }
        
        self.animateWindowResize = false
        
        self.removeHotKeyHandlers()
        hotKeysJumpHandlers = jumpKeys.map { key in
            let hotKey = HotKey(
                key: key,
                modifiers: [.option],
                keyDownHandler: {
                    if let workspaceUi = self.workspacesUi.first(where: { $0.key == key }) {
                        workspaceUi.onClick()
                        return
                    }
                    if let favoriteUi = self.favoritesUi.first(where: { $0.key == key }) {
                        favoriteUi.onClick()
                        return
                    }
                    if let hash = self.jumpCachedWindowKeyMap.first(where: { $0.value == key })?.key,
                       let cachedWindow = self.history.first(where: { $0.axuiElement.hashValue == hash }) {
                        self.onCachedWindowFocus(cachedWindow)
                        return
                    }
                },
            )
            return hotKey
        }
    }
    
    func rebuildAppsUi() {
        self.appsUi = buildAppsUi()
    }
    
    func removeHotKeyHandlers() {
        hotKeysJumpHandlers.forEach { $0.isPaused = true }
        hotKeysJumpHandlers.removeAll()
    }
}

// ВНИМАНИЕ!
// Строго контролировать скорость выполнения,
// на момент разработки это ~3млс.
@MainActor
private func buildAppsUi() -> [OptionTabAppUi] {
    let sortMap: [String: Int] = Dictionary(
        uniqueKeysWithValues: OptionTabPinDb.selectAll().map { ($0.bundle, $0.sort) }
    )
    
    // Работа с NSWorkspace.shared.runningApplications занимает много
    // времени, особенно вызовы .activationPolicy и .bundleIdentifier.
    // По этому работаем только с cachedWindows.
    let appsMap: [String: [CachedWindow]] = Dictionary(
        grouping: cachedWindows.map(\.value),
        by: { $0.appBundle },
    )

    let appsUi: [OptionTabAppUi] = appsMap.map { (_, cachedWindowsLocal) in
        let firstCachedWindow: CachedWindow = cachedWindowsLocal.first!
        let bundle: String = firstCachedWindow.appBundle
        return OptionTabAppUi(
            app: firstCachedWindow.nsRunningApplication,
            appName: firstCachedWindow.appName,
            bundle: bundle,
            sort: sortMap[bundle],
            icon: firstCachedWindow.icon,
            cachedWindows: cachedWindowsLocal.sorted { $0.title.lowercased() < $1.title.lowercased() },
        )
    }

    let res = appsUi.sorted {
        if let sort0 = $0.sort, let sort1 = $1.sort { return sort0 < sort1 }
        if $0.sort != nil { return true }
        if $1.sort != nil { return false }
        return $0.appName < $1.appName
    }
    return res
}

private func buildHistory() -> [CachedWindow] {
    return cachedWindows.map { $0.value }.sorted { w0, w1 in
        let stackIdx0: Int? = AppObserver.stackAxuiHashes.firstIndex(of: w0.axuiElement.hashValue)
        let stackIdx1: Int? = AppObserver.stackAxuiHashes.firstIndex(of: w1.axuiElement.hashValue)
        if let stackIdx0 = stackIdx0, let stackIdx1 = stackIdx1 {
            return stackIdx0 < stackIdx1
        }
        if stackIdx0 != nil { return true }
        if stackIdx1 != nil { return false }
        return w0.title.lowercased() < w1.title.lowercased()
    }
}
