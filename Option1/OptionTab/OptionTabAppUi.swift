import AppKit

struct OptionTabAppUi: Hashable {
    let app: NSRunningApplication
    let appName: String
    let bundle: String?
    let sort: Int?
    let icon: NSImage?
    let cachedWindows: [CachedWindow]
}
