import SwiftUI

class OptionTabManager {
    
    static let instance = OptionTabManager()
    
    ///
    
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
    
    ///
    
    private func focusCachedWindow(_ cachedWindow: CachedWindow) {
        try? WindowsManager.focusWindow(axuiElement: cachedWindow.axuiElement)
        closeWindow()
    }
    
    private func showWindow() {
        let optionTabData = OptionTabData(
            selectedCachedWindow: AppObserver.previousFocusedCachedWindow,
        )
        
        let contentHeight: Int = {
            let headersHeight: Int = optionTabData.appsUi.count * Int(OptionTabView.itemHeight + OptionTabView.itemHeaderPadding)
            let itemsHeight: Int = optionTabData.appsUi.flatMap(\.cachedWindows).count * Int(OptionTabView.itemHeight)
            let bottomPadding = Int(OptionTabView.itemHeaderPadding) + 2
            // Не знаю почему, но итоговый блок чуть выше чем рачеты
            let extraHeight: Int = 8
            return headersHeight + itemsHeight + bottomPadding + extraHeight
        }()
        
        let screenHeight: Int? = NSScreen.main.map { Int($0.visibleFrame.size.height) }
        let windowHeight: Int = {
            guard let screenHeight = screenHeight else {
                return contentHeight
            }
            return min(contentHeight, (screenHeight - 20))
        }()
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: windowHeight),
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
