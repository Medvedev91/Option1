import AppKit

struct OptionTabAppUi: Hashable {
    let app: NSRunningApplication? // nil means unknown app
    let cachedWindows: [CachedWindow]
}
