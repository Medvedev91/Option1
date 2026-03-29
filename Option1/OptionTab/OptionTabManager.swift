import SwiftUI

@MainActor
class OptionTabManager {
    
    static let instance = OptionTabManager()
    
    ///
    
    var isEnabled: Bool = KvDb.selectIsOptionTabEnabled()
    
    private var optionTabView: OptionTabView?
    
    func onOptionTabPressed() {
        if let optionTabView = optionTabView {
            let allCachedWindows: [CachedWindow] = optionTabView.data.appsUi.flatMap { $0.cachedWindows }
            if let selectedCachedWindow = optionTabView.data.selectedCachedWindow,
               let curIndex = allCachedWindows.firstIndex(of: selectedCachedWindow) {
                let nextIndex = curIndex + 1
                if (nextIndex + 1) > allCachedWindows.count {
                    optionTabView.data.selectedCachedWindow = allCachedWindows.first
                } else {
                    optionTabView.data.selectedCachedWindow = allCachedWindows[nextIndex]
                }
            } else {
                optionTabView.data.selectedCachedWindow = allCachedWindows.first
            }
            return
        }
        showWindow()
    }
    
    func onOptionShiftTabPressed() {
        if let optionTabView = optionTabView {
            let allCachedWindows: [CachedWindow] = optionTabView.data.appsUi.flatMap { $0.cachedWindows }
            if let selectedCachedWindow = optionTabView.data.selectedCachedWindow,
               let curIndex = allCachedWindows.firstIndex(of: selectedCachedWindow) {
                if curIndex > 0 {
                    optionTabView.data.selectedCachedWindow = allCachedWindows[curIndex - 1]
                } else {
                    optionTabView.data.selectedCachedWindow = allCachedWindows.last
                }
            } else {
                optionTabView.data.selectedCachedWindow = allCachedWindows.last
            }
            return
        }
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
    
    private func showWindow() {
        // Если открыто окно приложение Option1 (не Option-Tab),
        // то при нажатии на Option-Tab происходит фокус на Option1.
        closeAppWindow()
        
        let optionTabData = OptionTabData(
            selectedCachedWindow: AppObserver.previousFocusedCachedWindow,
        )
        
        let appsHeight: Int = {
            let headersHeight: CGFloat = Double(optionTabData.appsUi.count) * (OptionTabView.itemHeight + OptionTabView.itemHeaderPadding)
            let itemsHeight: CGFloat = Double(optionTabData.appsUi.flatMap(\.cachedWindows).count) * OptionTabView.itemHeight
            let bottomPadding = OptionTabView.itemHeaderPadding
            return Int((headersHeight + itemsHeight + bottomPadding).rounded(.up))
        }()
        
        let menuHeight: Int = {
            let separators: CGFloat = OptionTabView.menuSeparatorHeight * 2.0
            let vPaddings: CGFloat = OptionTabView.itemHeaderPadding * 2.0
            let settingsHeight: CGFloat = OptionTabView.itemHeight
            let workspacesHeight: CGFloat = Double(MenuBarManager.instance.workspacesUi.count) * OptionTabView.itemHeight
            let bindsHeight: CGFloat = MenuBarManager.instance.bindsUi.map { bindUi in
                bindUi.subtitle == nil ? OptionTabView.itemHeight : OptionTabView.itemTwoLinesHeight
            }.reduce(0, +)
            return Int((separators + vPaddings + settingsHeight + workspacesHeight + bindsHeight).rounded(.up))
        }()
        
        let contentHeight: Int = max(appsHeight, menuHeight)
        
        let screenHeight: Int? = NSScreen.main.map { Int($0.visibleFrame.size.height) }
        let windowHeight: Int = {
            guard let screenHeight = screenHeight else {
                return contentHeight
            }
            // Не нужно вертикальных отступов для визуальной
            // наглядности если списов не входит в экран.
            return min(contentHeight, screenHeight)
        }()
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Int(OptionTabView.fullWidth), height: windowHeight),
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
            isFullHeight: windowHeight == screenHeight,
        )
        
        window.contentView = NSHostingView(rootView: optionTabView)
        window.center()
        window.level = .mainMenu + 1
        // Fix crash on close https://stackoverflow.com/a/78684365
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        Task { @MainActor in
            try await Task.sleep(nanoseconds: 80_000_000)
            self.optionTabView?.window.makeKeyAndOrderFront(nil)
        }
        
        self.optionTabView = optionTabView
    }
}
