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
        try? WindowsManager.focusWindow(axuiElement: selectedCachedWindow.axuiElement)
        closeWindow()
    }
    
    func closeWindow() {
        self.optionTabView?.window.close()
        self.optionTabView = nil
    }
    
    ///
    
    private func showWindow() {
        let optionTabData = OptionTabData()
        
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
        )
        
        window.contentView = NSHostingView(rootView: optionTabView)
        window.center()
        window.level = .mainMenu + 1
        window.makeKeyAndOrderFront(nil)
        // Fix crash on close https://stackoverflow.com/a/78684365
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        // Alpha 0.01 иначе курсор реагирует на содержимое под окном.
        window.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.01)
        
        self.optionTabView = optionTabView
    }
}
