import SwiftUI
import Cocoa

struct WorkspaceScreen: View {
    
    let workspaceDb: WorkspaceDb?
    
    ///
    
    @State private var activeAppsUi: [ActiveAppUi] = []
    
    // 2 секунды чтобы в т.ч. успеть CachedWindow.cleanClosed()
    private let updateActiveAppsUiTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            
            ForEach(HotKeysUtils.keys, id: \.self) { key in
                WorkspaceBindView(
                    key: key,
                    workspaceDb: workspaceDb,
                )
                .padding(.top, key == .one ? 8 : 0)
            }
            
            Divider()
                .padding()
            
            VStack(spacing: 12) {
                ForEach(activeAppsUi, id: \.app) { activeAppUi in
                    ActiveAppView(activeAppUi: activeAppUi)
                }
            }
            .padding(.bottom, 24)
        }
        .onReceive(updateActiveAppsUiTimer) { _ in
            updateActiveAppsUi()
        }
        .onAppear {
            updateActiveAppsUi()
        }
        .navigationTitle(workspaceDb?.name ?? "Shared")
    }
    
    private func updateActiveAppsUi() {
        CachedWindow.cleanClosed()
        // Running Apps
        var localActiveAppsUi: [ActiveAppUi] = []
        NSWorkspace.shared.runningApplications.forEach { app in
            guard let bundle: String = app.bundleIdentifier else { return }
            let appCachedWindows: [CachedWindow] = cachedWindows
                .map { $0.value }
                .filter { $0.appBundle == bundle }
                .sorted { $0.title < $1.title }
            guard !appCachedWindows.isEmpty else { return }
            let activeAppUi = ActiveAppUi(app: app, cachedWindows: appCachedWindows)
            localActiveAppsUi.append(activeAppUi)
        }
        // Other Apps
        let usedCachedWindows: [CachedWindow] = localActiveAppsUi.flatMap(\.cachedWindows)
        let otherCachedWindows: [CachedWindow] = cachedWindows
            .map { $0.value }
            .filter { !usedCachedWindows.contains($0) }
        if !otherCachedWindows.isEmpty {
            localActiveAppsUi.append(ActiveAppUi(app: nil, cachedWindows: otherCachedWindows))
        }
        ///
        activeAppsUi = localActiveAppsUi
    }
}

///

private struct ActiveAppUi: Hashable {
    let app: NSRunningApplication? // nil means unknown app
    let cachedWindows: [CachedWindow]
}

private struct ActiveAppView: View {
    
    let activeAppUi: ActiveAppUi
    
    ///
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Text(activeAppUi.app?.localizedName ?? "Other")
                    .fontWeight(.bold)
                Text(" - " + (activeAppUi.app?.bundleIdentifier ?? "Other"))
                Spacer()
            }
            .padding(.horizontal)
            ForEach(activeAppUi.cachedWindows, id: \.self) { cachedWindow in
                Text(cachedWindow.title)
                    .textAlign(.leading)
                    .padding(.horizontal)
            }
        }
    }
}
