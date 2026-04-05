import AppKit

@MainActor
class OptionTabData: ObservableObject {
    
    @Published var uiMode: OptionTabUiMode
    @Published var appsUi: [OptionTabAppUi]
    @Published var history: [CachedWindow]
    @Published var selectedCachedWindow: CachedWindow?
    @Published var favoritesUi: [OptionTabFavoriteUi]
    
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
            let workspacesHeight: CGFloat = Double(MenuBarManager.instance.workspacesUi.count) * OptionTabView.itemHeight
            let bindsHeight: CGFloat = MenuBarManager.instance.bindsUi.map { bindUi in
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
    
    // ВНИМАНИЕ!
    // Строго контролировать скорость выполнения,
    // на момент разработки это ~3млс.
    init(
        uiMode: OptionTabUiMode,
    ) {
        // print(";;; e  \(timeMls())")
        self.uiMode = uiMode
        
        // Clean closed only once
        self.appsUi = buildAppsUi(doCleanClosed: true)
        let history = buildHistory(doCleanClosed: false)
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
        
        self.favoritesUi = FavoriteDb.selectAllSorted().map {
            OptionTabFavoriteUi(favoriteDb: $0)
        }
        // print(";;; e 9  \(timeMls())")
    }
    
    func rebuildAppsUi() {
        self.appsUi = buildAppsUi(doCleanClosed: true)
    }
}

// ВНИМАНИЕ!
// Строго контролировать скорость выполнения,
// на момент разработки это ~3млс.
@MainActor
private func buildAppsUi(doCleanClosed: Bool) -> [OptionTabAppUi] {
    // print(";;; f 0  \(timeMls())")
    if doCleanClosed {
        CachedWindow.cleanClosed__slow(reportIfSlow: false)
    }
    
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
    // print(";;; f 9  \(timeMls())")
    return res
}

private func buildHistory(doCleanClosed: Bool) -> [CachedWindow] {
    if doCleanClosed {
        CachedWindow.cleanClosed__slow(reportIfSlow: false)
    }
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
