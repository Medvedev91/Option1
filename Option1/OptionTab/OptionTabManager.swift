import SwiftUI

@MainActor
class OptionTabManager {
    
    static let instance = OptionTabManager()
    
    ///
    
    var isEnabled: Bool = KvDb.selectIsOptionTabEnabled()
    
    private let optionTabView: OptionTabView
    
    private var isOpen = false
    private var delayedOpening: (() -> Void)? = nil
    
    private init() {
        let optionTabData = OptionTabData(
            uiMode: .history,
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
                OptionTabManager.instance.focusCachedWindow(cachedWindow)
            },
            closeWindow: {
                OptionTabManager.instance.closeWindow()
            },
        )
        
        window.contentView = NSHostingView(rootView: optionTabView)
        window.level = .mainMenu + 1
        // Fix crash on close https://stackoverflow.com/a/78684365
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        self.optionTabView = optionTabView
    }
    
    func onOptionTabPressed(fromJk: Bool) {
        if isOpen {
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
   
    func onOptionShiftTabPressed() {
        if isOpen {
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
    }
    
    func onOptionKeyUp() {
        guard let selectedCachedWindow = optionTabView?.data.selectedCachedWindow else {
            closeWindow()
            return
        }
        
        // Т.к. функция может вызываться из вне просто так,
        // исключаем вызовы когда окно не было открыто.
        if !isOpen {
            return
        }
        
        closeWindow()
        if let selectedCachedWindow = optionTabView.data.selectedCachedWindow {
            focusCachedWindow(selectedCachedWindow)
        }
    }
    
    func openWindow(
        uiMode: OptionTabUiMode,
    ) {
        // Если открыто окно приложение Option1 (не Option-Tab),
        // то при нажатии на Option-Tab происходит фокус на Option1.
        closeAppWindow()

        isOpen = true
        
        optionTabView.data.rebuild(
            uiMode: uiMode,
        )
        
        optionTabView.window.makeKeyAndOrderFront(nil)
        
        HotKeysUtils.enableOptionTabJkHotKeys()
        HotKeysUtils.enableOptionTabArrowsHotKeys()
    }
    
    func closeWindow() {
        isOpen = false
        self.optionTabView.window.close()
        HotKeysUtils.disableOptionTabArrowsHotKeys()
        if KvDb.selectOptionTabDbMode() != .jk {
            HotKeysUtils.disableOptionTabJkHotKeys()
        }
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
}
