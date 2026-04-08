import AppKit

private let otherFlags: [NSEvent.ModifierFlags] = [
    .capsLock, .shift, .control, .command, .numericPad, .help, .function,
]

@MainActor
class OptionTabDoubleManager {
    
    private static var lastKeyDownMls: Int64? = nil
    
    static func handleKeyDown(event: NSEvent) {
        let type = event.type
        // Разрешаем движение мышью т.к. можно задеть случайно
        if [.mouseMoved, .scrollWheel].contains(type) {
            return
        }
        // При любом типе событий кроме изменения флага - отмена
        if type != .flagsChanged {
            cancel()
            return
        }
        let flags = event.modifierFlags
        if otherFlags.first(where: { flags.contains($0) }) != nil {
            cancel()
            return
        }
        if flags.contains(.option) {
            if let lastKeyDownMls = lastKeyDownMls {
                let diffMls = timeMls() - lastKeyDownMls
                if diffMls < 400 {
                    let uiMode: OptionTabUiMode = switch KvDb.selectOptionTabDbMode() {
                    case .apps: .apps
                    case .history: .history
                    case .jk: .apps
                    }
                    OptionTabManager.instance.openWindow(uiMode: uiMode, withPreselectedCachedWindow: false)
                }
                cancel()
            } else {
                lastKeyDownMls = timeMls()
            }
        }
        // Не реагируем на else т.к. это отжатие
    }
    
    static func cancel() {
        lastKeyDownMls = nil
    }
}
