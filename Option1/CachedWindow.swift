import AppKit

// AXUIElement hash: CachedWindow
var cachedWindows: [Int: CachedWindow] = [:]

struct CachedWindow: Hashable {
    
    let axuiElement: AXUIElement
    let pid: pid_t
    let axuiElementId: AXUIElementID
    let title: String
    let nsRunningApplication: NSRunningApplication
    let appBundle: String
    let appName: String
    let icon: NSImage?
    let shellWithNewWindow: String?
    
    static func addByAxuiElement(
        nsRunningApplication: NSRunningApplication,
        axuiElement: AXUIElement,
        shellWithNewWindow: String? = nil,
    ) throws {
        Task { @MainActor in
            //
            // Обновляем именно тут по нескольким причинам:
            //
            // 1.
            // Вызываем именно до добавления в cachedWindows, из-за особенностей
            // локиги cleanClosed__slow(). Если проверять после добавления, то
            // cleanClosed__slow() может по ошибке удалить все окна т.к. будет добавлено
            // одно точно существующее а остальные еще недоступны после пробуждения.
            //
            // 2.
            // После закрытия окна вызывается AppObserver.handleNotification(),
            // а нам как раз надо очистить закрытые окна.
            //
            cleanClosed__slow(reportIfSlow: false)
            
            if
                let pid = try axuiElement.pid(),
                let axuiElementId = axuiElement.id(),
                let title = try axuiElement.title(),
                let bundleIdentifier = nsRunningApplication.bundleIdentifier,
                let appName = nsRunningApplication.localizedName {
                
                // Часто при старте приложения при обращении и записи в cachedWindows
                // происходит крэш. Пытаюсь исправить через MainActor.
                let oldCachedWindow: CachedWindow? = cachedWindows[axuiElement.hashValue]
                let newCachedWindow = CachedWindow(
                    axuiElement: axuiElement,
                    pid: pid,
                    axuiElementId: axuiElementId,
                    title: title,
                    nsRunningApplication: nsRunningApplication,
                    appBundle: bundleIdentifier,
                    appName: appName,
                    icon: nsRunningApplication.icon,
                    shellWithNewWindow: shellWithNewWindow ?? oldCachedWindow?.shellWithNewWindow,
                )
                cachedWindows[axuiElement.hashValue] = newCachedWindow
            }
        }
    }
    
    // ВНИМАНИЕ! SUPER SLOW `.allWindows()`
    static func addByApp(_ app: NSRunningApplication) throws {
        let pid = app.processIdentifier
        try AXUIElementCreateApplication(pid).allWindows(pid).forEach { axuiElement in
            try CachedWindow.addByAxuiElement(nsRunningApplication: app, axuiElement: axuiElement)
        }
    }
    
    //
    // Внимание 1
    // Вызов функции занимает время хоть и не много: 2-50млс,
    // не желательно вызывать в критичных местах.
    //
    // Внимание 2
    // Изучить реализацию, там компромисная логика.
    //
    // Внимание 3
    // Вызывать только когда важен результат, т.е. перед использованием cachedWindows.
    //
    // MainActor т.к. были крэши при обращении к cachedWindows.
    //
    @MainActor
    static func cleanClosed__slow(reportIfSlow: Bool = true) {
        let timeStartMls = timeMls()
        let windowsToRemove: [Int: CachedWindow] = cachedWindows.filter { _, cachedWindow in
            !cachedWindow.axuiElement.isElementExists()
        }
        let elapsedMls = timeMls() - timeStartMls
        reportLog("cleanClosed__slow elapsed \(elapsedMls) mls")
        if reportIfSlow, elapsedMls > 100 {
            reportApi("cleanClosed__slow too slow: \(elapsedMls) mls, cachedWindows: \(cachedWindows.count)")
        }
        
        // Внимание! Компромисная логика!
        // В момент когда macOS на экране ввода логина, при вызове .isElementExists()
        // всегда возвращается false, хотя по факту окна восстановятся после пробуждения.
        // Это значит что как только macOS уходит в фон, окна удаляются и Option1
        // НЕ работает после пробуждения. Это легко можно добиться, если открыть экран
        // воркспейса (на нем по таймеру просиходит вызов .cleanClosed__slow()) и выйти на
        // экран ввода логина macOS. Я не нашел способа определять что окно еще живое
        // в момент когда macOS в фоне, по этому единственный способ избегать ошибочного
        // удаления всех окон - проверять, если все окна удаляются разом - значит фон.
        // Такая логика может давать сбой если нужно удалить действительно последнее окно,
        // но это очень редкая ситуация когда человек закрывает все программы. Даже если
        // это так, то ничего страшного, ведь открывать больше нечего.
        if windowsToRemove.count == cachedWindows.count {
            return
        }
        windowsToRemove.forEach { hashValue, _ in
            cachedWindows.removeValue(forKey: hashValue)
        }
    }
    
    static func cleanByBundle(_ bundle: String) {
        cachedWindows
            .filter { $0.value.appBundle == bundle }
            .forEach { hashValue, _ in
                cachedWindows.removeValue(forKey: hashValue)
            }
    }
}
