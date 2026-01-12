import AppKit

var cachedWindows: [Int: CachedWindow] = [:]

struct CachedWindow: Hashable {
    
    let axuiElement: AXUIElement
    let pid: pid_t
    let axuiElementId: AXUIElementID
    let title: String
    let appBundle: String
    
    static func addByAxuiElement(
        nsRunningApplication: NSRunningApplication,
        axuiElement: AXUIElement
    ) throws {
        if
            let pid = try axuiElement.pid(),
            let axuiElementId = axuiElement.id(),
            let title = try axuiElement.title(),
            let bundleIdentifier = nsRunningApplication.bundleIdentifier {
            cachedWindows[axuiElement.hashValue] = CachedWindow(
                axuiElement: axuiElement,
                pid: pid,
                axuiElementId: axuiElementId,
                title: title,
                appBundle: bundleIdentifier
            )
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
    static func cleanClosed() {
        let windowsToRemove: [Int: CachedWindow] = cachedWindows.filter { _, cachedWindow in
            !cachedWindow.axuiElement.isElementExists()
        }
        // Внимание! Компромисная логика!
        // В момент когда macOS на экране ввода логина, при вызове .isElementExists()
        // всегда возвращается false, хотя по факту окна восстановятся после пробуждения.
        // Это значит что как только macOS уходит в фон, окна удаляются и Option 1
        // НЕ работает после пробуждения. Это легко можно добиться, если открыть экран
        // воркспейса (на нем по таймеру просиходит вызов .cleanClosed()) и выйти на
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
