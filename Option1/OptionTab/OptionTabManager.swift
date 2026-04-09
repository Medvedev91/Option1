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
            onCachedWindowFocus: { cachedWindow in
                OptionTabManager.instance.focusCachedWindow(cachedWindow)
            },
            closeWindow: {
                OptionTabManager.instance.closeWindow()
            },
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
            }
        } else if let delayedOpening = delayedOpening {
            delayedOpening()
            // Т.к. это происходит если я нажимаю повторно пока
            // ожидается открытие, нужно эмитировать повторное нажатие.
            onOptionTabPressed(fromJk: fromJk)
        } else if fromJk {
            openWindow(uiMode: .history, withPreselectedCachedWindow: true)
        } else {
            let uiMode: OptionTabUiMode = switch KvDb.selectOptionTabDbMode() {
            case .apps: .apps
            case .history: .history
            case .jk: .apps // Не может случиться т.к. выше условие с fromJk
            }
            self.delayedOpening = {
                self.delayedOpening = nil
                self.openWindow(uiMode: uiMode, withPreselectedCachedWindow: true)
            }
            Task {
                try await Task.sleep(nanoseconds: 80_000_000)
                if let delayedOpening = self.delayedOpening {
                    delayedOpening()
                }
            }
        }
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
        // Если отжали Option до того как появилось окно,
        // т.е. быстрое переключение между окнами.
        if delayedOpening != nil {
            self.delayedOpening = nil
            closeWindow() // На всякий случай
            let cwKeys = cachedWindows.keys
            let hashes = AppObserver.stackAxuiHashes.filter { cwKeys.contains($0) }
            if hashes.count >= 2, let axuiElement = cachedWindows[hashes[1]]?.axuiElement {
                try? WindowsManager.focusWindow(axuiElement: axuiElement)
            }
            return
        }
        
        // Т.к. функция может вызываться из вне просто так,
        // исключаем вызовы когда окно не было открыто.
        if !isOpen {
            closeWindow() // На всякий случай
            return
        }
        
        closeWindow()
        if let selectedCachedWindow = optionTabView.data.selectedCachedWindow {
            focusCachedWindow(selectedCachedWindow)
        }
    }
    
    func openWindow(
        uiMode: OptionTabUiMode,
        withPreselectedCachedWindow: Bool,
    ) {
        // Если открыто окно приложение Option1 (не Option-Tab),
        // то при нажатии на Option-Tab происходит фокус на Option1.
        closeAppWindow()

        isOpen = true
        
        optionTabView.data.rebuild(
            uiMode: uiMode,
            withPreselectedCachedWindow: withPreselectedCachedWindow,
        )
        
        optionTabView.window.makeKeyAndOrderFront(nil)
        // Устанавливает фокус на окно, но после закрытия фокус не
        // не возвращается на прежнюю программу что не удобно.
        // Можно сохранять окно что было в фокусе и потом возвращать,
        // но это много запутанной логики.
        // NSApplication.shared.activate(ignoringOtherApps: false)
        
        HotKeysUtils.enableOptionTabJkHotKeys()
        HotKeysUtils.enableOptionTabArrowsHotKeys()
        
        BadgesManager.startLiveUpdates()
    }
    
    func closeWindow() {
        isOpen = false
        optionTabView.window.close()
        
        HotKeysUtils.disableOptionTabArrowsHotKeys()
        if KvDb.selectOptionTabDbMode() != .jk {
            HotKeysUtils.disableOptionTabJkHotKeys()
        }
        
        optionTabView.data.isJkInfoPresented = false
        optionTabView.data.isKeepShortcutsGlobalInfoPresented = false
        if !optionTabView.data.isKeepJumpsGlobal {
            optionTabView.data.removeHotKeyHandlers()
        }
        
        Task {
            // Просто удобное место для вызова.
            // Человек может увидеть что-то не
            // существущее, и переоткрыть Option-Tab.
            CachedWindow.cleanClosed__slow(reportIfSlow: false)
        }
        
        BadgesManager.stopLiveUpdates()
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
