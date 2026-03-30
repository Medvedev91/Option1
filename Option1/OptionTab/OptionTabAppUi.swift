import AppKit

struct OptionTabAppUi: Hashable {
    let app: NSRunningApplication? // nil means unknown app
    let bundle: String?
    let sort: Int?
    let cachedWindows: [CachedWindow]
}
