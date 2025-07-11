import Cocoa

class Application {
    
    var localizedName: String?
    var bundleIdentifier: String?
    var executableURL: URL?
    
    init(_ runningApplication: NSRunningApplication) {
        localizedName = runningApplication.localizedName
        bundleIdentifier = runningApplication.bundleIdentifier
        executableURL = runningApplication.executableURL
    }
}
