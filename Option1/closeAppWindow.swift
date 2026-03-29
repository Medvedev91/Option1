import AppKit

func closeAppWindow() {
    // Не подходит т.к. закрывает окно приложения
    // только если если оно на переднем плане.
    // NSApplication.shared.keyWindow?.close()
    
    NSApplication.shared.windows.forEach { window in
        // Кроме окна приложения есть еще окно Menu Bar
        // и все закрытие окна Option-Tab (по идее их
        // их надо удалять но надо разбираться).
        if window.styleMask.contains(.closable) {
            window.close()
        }
    }
}
