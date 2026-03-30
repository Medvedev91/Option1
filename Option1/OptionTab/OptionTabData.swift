import AppKit

@MainActor
class OptionTabData: ObservableObject {
    
    @Published var appsUi: [OptionTabAppUi]
    @Published var selectedCachedWindow: CachedWindow?
    
    init(
        selectedCachedWindow: CachedWindow?,
    ) {
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
                cachedWindows: otherCachedWindows,
            ))
        }
        
        self.appsUi = appsUi.sorted { ($0.app?.localizedName ?? "") < ($1.app?.localizedName ?? "") }
        self.selectedCachedWindow = selectedCachedWindow
    }
}
