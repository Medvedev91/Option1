import AppKit

@MainActor
class OptionTabData: ObservableObject {
    
    @Published var uiMode: OptionTabUiMode
    @Published var appsUi: [OptionTabAppUi]
    @Published var history: [CachedWindow]
    @Published var selectedCachedWindow: CachedWindow?
    
    var windowHeight: Int {
        let windowsHeight: Int = {
            switch uiMode {
            case .apps:
                let headersHeight: CGFloat = Double(appsUi.count) * OptionTabView.itemHeaderPadding
                let itemsHeight: CGFloat = Double(appsUi.flatMap(\.cachedWindows).count) * OptionTabView.itemHeight
                let bottomPadding = OptionTabView.itemHeaderPadding
                return Int((headersHeight + itemsHeight + bottomPadding).rounded(.up))
            case .history:
                let headerHeight: CGFloat = OptionTabView.itemHeaderPadding
                let itemsHeight: CGFloat = Double(history.count) * OptionTabView.itemHeight
                let bottomPadding: CGFloat = OptionTabView.itemHeaderPadding
                return Int((headerHeight + itemsHeight + bottomPadding).rounded(.up))
            }
        }()
        
        let menuHeight: Int = {
            let separators: CGFloat = OptionTabView.menuDividerHeight * 3.0
            let vPaddings: CGFloat = OptionTabView.itemHeaderPadding * 2.0
            let systemButtonsHeight: CGFloat = OptionTabView.itemHeight * 2.0 // Settings, Modes.
            let workspacesHeight: CGFloat = Double(MenuBarManager.instance.workspacesUi.count) * OptionTabView.itemHeight
            let bindsHeight: CGFloat = MenuBarManager.instance.bindsUi.map { bindUi in
                bindUi.subtitle == nil ? OptionTabView.itemHeight : OptionTabView.itemTwoLinesHeight
            }.reduce(0, +)
            return Int((separators + vPaddings + systemButtonsHeight + workspacesHeight + bindsHeight).rounded(.up))
        }()
        
        let contentHeight: Int = max(windowsHeight, menuHeight)
        
        let windowHeight: Int = {
            guard let screenHeight = screenHeightOrNil() else {
                return contentHeight
            }
            // Не нужно вертикальных отступов для визуальной
            // наглядности если список не входит в экран.
            return min(contentHeight, screenHeight)
        }()
        
        return windowHeight
    }
    
    var isFullHeight: Bool {
        windowHeight == screenHeightOrNil()
    }
    
    init(
        uiMode: OptionTabUiMode,
    ) {
        self.uiMode = uiMode
        
        // Clean closed only once
        self.appsUi = buildAppsUi(doCleanClosed: true)
        self.history = buildHistory(doCleanClosed: false)
        
        self.selectedCachedWindow = {
            if let w = (AppObserver.getCachedWindowFromStackByIdxOrNil(1) ?? AppObserver.getCachedWindowFromStackByIdxOrNil(0)) {
                return w
            }
            return switch uiMode {
            case .apps:
                appsUi.first?.cachedWindows.first
            case .history:
                history.first
            }
        }()
    }
    
    func rebuildAppsUi() {
        self.appsUi = buildAppsUi(doCleanClosed: true)
    }
}

@MainActor
private func buildAppsUi(doCleanClosed: Bool) -> [OptionTabAppUi] {
    if doCleanClosed {
        CachedWindow.cleanClosed__slow(reportIfSlow: false)
    }
    
    let sortMap: [String: Int] = Dictionary(
        uniqueKeysWithValues: OptionTabPinDb.selectAll().map { ($0.bundle, $0.sort) }
    )
    
    // Running Apps
    var appsUi: [OptionTabAppUi] = []
    NSWorkspace.shared.runningApplications.forEach { app in
        guard let bundle: String = app.bundleIdentifier else { return }
        let appCachedWindows: [CachedWindow] = cachedWindows
            .map { $0.value }
            .filter { $0.appBundle == bundle }
            .sorted { $0.title.lowercased() < $1.title.lowercased() }
        guard !appCachedWindows.isEmpty else { return }
        let activeAppUi = OptionTabAppUi(
            app: app,
            bundle: bundle,
            sort: sortMap[bundle],
            icon: app.icon,
            cachedWindows: appCachedWindows,
        )
        appsUi.append(activeAppUi)
    }
    
    // Other Apps
    let usedCachedWindows: [CachedWindow] = appsUi.flatMap(\.cachedWindows)
    let otherCachedWindows: [CachedWindow] = cachedWindows
        .map { $0.value }
        .filter { !usedCachedWindows.contains($0) }
    if !otherCachedWindows.isEmpty {
        appsUi.append(OptionTabAppUi(
            app: nil,
            bundle: nil,
            sort: nil,
            icon: nil,
            cachedWindows: otherCachedWindows,
        ))
    }
    
    return appsUi.sorted {
        if let sort0 = $0.sort, let sort1 = $1.sort { return sort0 < sort1 }
        if $0.sort != nil { return true }
        if $1.sort != nil { return false }
        return ($0.app?.localizedName ?? "") < ($1.app?.localizedName ?? "")
    }
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
