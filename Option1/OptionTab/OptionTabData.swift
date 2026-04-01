import AppKit

@MainActor
class OptionTabData: ObservableObject {
    
    @Published var appsUi: [OptionTabAppUi]
    @Published var selectedCachedWindow: CachedWindow?
    
    init(
        selectedCachedWindow: CachedWindow?,
    ) {
        self.appsUi = buildAppsUi()
        self.selectedCachedWindow = selectedCachedWindow
    }
    
    func rebuildAppsUi() {
        self.appsUi = buildAppsUi()
    }
}

@MainActor
private func buildAppsUi() -> [OptionTabAppUi] {
    CachedWindow.cleanClosed__slow(reportIfSlow: false)
    
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

private func buildStack(doCleanClosed: Bool) -> [CachedWindow] {
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
