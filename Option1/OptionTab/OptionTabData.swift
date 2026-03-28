import AppKit

class OptionTabData: ObservableObject {
    
    let appsUi: [OptionTabAppUi]
    @Published var selectedCachedWindow: CachedWindow? = nil

    init() {
        CachedWindow.cleanClosed__slow(reportIfSlow: false)
        
        // Running Apps
        var appsUi: [OptionTabAppUi] = []
        NSWorkspace.shared.runningApplications.forEach { app in
            guard let bundle: String = app.bundleIdentifier else { return }
            let appCachedWindows: [CachedWindow] = cachedWindows
                .map { $0.value }
                .filter { $0.appBundle == bundle }
                .sorted { $0.title < $1.title }
            guard !appCachedWindows.isEmpty else { return }
            let activeAppUi = OptionTabAppUi(app: app, cachedWindows: appCachedWindows)
            appsUi.append(activeAppUi)
        }
        
        // Other Apps
        let usedCachedWindows: [CachedWindow] = appsUi.flatMap(\.cachedWindows)
        let otherCachedWindows: [CachedWindow] = cachedWindows
            .map { $0.value }
            .filter { !usedCachedWindows.contains($0) }
        if !otherCachedWindows.isEmpty {
            appsUi.append(OptionTabAppUi(app: nil, cachedWindows: otherCachedWindows))
        }
        
        self.appsUi = appsUi.sorted { ($0.app?.localizedName ?? "") < ($1.app?.localizedName ?? "") }
    }
}
