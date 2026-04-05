import SwiftUI

@MainActor
class OptionTabManager {
    
    static let instance = OptionTabManager()
    
    ///
    
    var isEnabled: Bool = KvDb.selectIsOptionTabEnabled()
    
    private var optionTabView: OptionTabView?
    
    func onOptionTabPressed(fromJk: Bool) {
        if let optionTabView = optionTabView {
            let data = optionTabView.data
            switch data.uiMode {
            case.apps:
                let allCachedWindows: [CachedWindow] = data.appsUi.flatMap { $0.cachedWindows }
                if let selectedCachedWindow = data.selectedCachedWindow,
                   let curIndex = allCachedWindows.firstIndex(of: selectedCachedWindow) {
                    let nextIndex = curIndex + 1
                    if nextIndex >= allCachedWindows.count {
                        data.selectedCachedWindow = allCachedWindows.first
                    } else {
                        data.selectedCachedWindow = allCachedWindows[nextIndex]
                    }
                } else {
                    data.selectedCachedWindow = allCachedWindows.first
                }
            case.history:
                let history = data.history
                if let selectedCachedWindow = data.selectedCachedWindow,
                   let curIndex = history.firstIndex(of: selectedCachedWindow) {
                    let nextIndex = curIndex + 1
                    if nextIndex >= history.count {
                        data.selectedCachedWindow = history.first
                    } else {
                        data.selectedCachedWindow = history[nextIndex]
                    }
                } else {
                    data.selectedCachedWindow = history.first
                }
                break
            }
            return
        }
        buildWindow(fromJk: fromJk)
    }
    
    func onOptionShiftTabPressed(fromJk: Bool) {
        if let optionTabView = optionTabView {
            let data = optionTabView.data
            switch data.uiMode {
            case .apps:
                let allCachedWindows: [CachedWindow] = data.appsUi.flatMap { $0.cachedWindows }
                if let selectedCachedWindow = data.selectedCachedWindow,
                   let curIndex = allCachedWindows.firstIndex(of: selectedCachedWindow) {
                    if curIndex > 0 {
                        data.selectedCachedWindow = allCachedWindows[curIndex - 1]
                    } else {
                        data.selectedCachedWindow = allCachedWindows.last
                    }
                } else {
                    data.selectedCachedWindow = allCachedWindows.last
                }
            case .history:
                let history = data.history
                if let selectedCachedWindow = data.selectedCachedWindow,
                   let curIndex = history.firstIndex(of: selectedCachedWindow) {
                    if curIndex > 0 {
                        data.selectedCachedWindow = history[curIndex - 1]
                    } else {
                        data.selectedCachedWindow = history.last
                    }
                } else {
                    optionTabView.data.selectedCachedWindow = history.last
                }
            }
            return
        }
        buildWindow(fromJk: fromJk)
    }
    
    func onOptionKeyUp() {
        guard let selectedCachedWindow = optionTabView?.data.selectedCachedWindow else {
            closeWindow()
            return
        }
        focusCachedWindow(selectedCachedWindow)
    }
    
    func closeWindow() {
        self.optionTabView?.window.close()
        self.optionTabView = nil
        if KvDb.selectOptionTabDbMode() != .jk {
            HotKeysUtils.disableOptionTabJkHotKeys()
        }
        HotKeysUtils.disableOptionTabArrowsHotKeys()
    }
    
    func setIsEnabled(_ isEnabled: Bool) {
        self.isEnabled = isEnabled
        KvDb.upsertIsOptionTabEnabled(isEnabled)
        if isEnabled {
            HotKeysUtils.enableOptionTab()
        } else {
            HotKeysUtils.disableOptionTab()
        }
    }
    
    ///
    
    private func focusCachedWindow(_ cachedWindow: CachedWindow) {
        try? WindowsManager.focusWindow(axuiElement: cachedWindow.axuiElement)
        closeWindow()
    }
    
    private func buildWindow(fromJk: Bool) {
        // Нужно начать как можно раньше
        BadgesManager.updateAsync()
        
        // Если открыто окно приложение Option1 (не Option-Tab),
        // то при нажатии на Option-Tab происходит фокус на Option1.
        closeAppWindow()
        
        let uiMode: OptionTabUiMode = switch KvDb.selectOptionTabDbMode() {
        case .apps: .apps
        case .history: .history
        case .jk: fromJk ? .history : .apps
        }
        let optionTabData = OptionTabData(
            uiMode: uiMode,
        )
        
        let window = NSWindow(
            contentRect: optionTabData.windowSize.nsRect,
            styleMask: [],
            backing: .buffered,
            defer: false,
        )
        
        let optionTabView = OptionTabView(
            window: window,
            data: optionTabData,
            onCachedWindowFocus: { cachedWindow in
                self.focusCachedWindow(cachedWindow)
            },
            closeWindow: {
                self.closeWindow()
            },
        )
        
        window.contentView = NSHostingView(rootView: optionTabView)
        window.level = .mainMenu + 1
        // Fix crash on close https://stackoverflow.com/a/78684365
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        self.optionTabView = optionTabView
        
        if fromJk {
            self.optionTabView?.window.makeKeyAndOrderFront(nil)
        } else {
            Task { @MainActor in
                try await Task.sleep(nanoseconds: 80_000_000)
                self.optionTabView?.window.makeKeyAndOrderFront(nil)
            }
        }
        
        HotKeysUtils.enableOptionTabJkHotKeys()
        HotKeysUtils.enableOptionTabArrowsHotKeys()
    }
}
