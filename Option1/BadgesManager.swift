import Foundation
import CoreFoundation

@MainActor
class BadgesManager: ObservableObject {
    
    static let instance = BadgesManager()
    
    @Published var dictionary: [String: String] = [:]
    
    // Based on https://stackoverflow.com/a/75167602
    static func updateAsync() {
        Task {
            let timeStartMls = timeMls()
            
            let CoreServiceBundle = CFBundleGetBundleWithIdentifier("com.apple.CoreServices" as CFString)
            
            let GetRunningApplicationArray: () -> [CFTypeRef] = {
                let functionPtr = CFBundleGetFunctionPointerForName(CoreServiceBundle, "_LSCopyRunningApplicationArray" as CFString)
                return unsafeBitCast(functionPtr,to:(@convention(c)(UInt)->[CFTypeRef]).self)(0xfffffffe)
            }
            
            let GetApplicationInformation: (CFTypeRef) -> [String:CFTypeRef] = { app in
                let functionPtr = CFBundleGetFunctionPointerForName(CoreServiceBundle, "_LSCopyApplicationInformation" as CFString)
                return unsafeBitCast(functionPtr, to: (@convention(c)(UInt, Any, Any)->[String:CFTypeRef]).self)(0xffffffff, app, 0)
            }
            
            let badgeLabelKey = "StatusLabel"
            
            let apps = GetRunningApplicationArray()
            let appInfos = apps.map { GetApplicationInformation($0) }
            
            var dictionaryLocal: [String: String] = [:]
            appInfos
                .filter{ $0.keys.contains(badgeLabelKey) }
                .reduce(into: [:]) { $0[$1[kCFBundleIdentifierKey as String] as! String] = ($1[badgeLabelKey] as! [String:CFTypeRef])["label"] }
                .forEach { (key, value) in
                    dictionaryLocal[key] = value as? String
                }
            
            BadgesManager.instance.dictionary = dictionaryLocal
            
            let elapsedMls = timeMls() - timeStartMls
            if elapsedMls > 50 {
                reportApi("BadgesManager.updateAsync() too slow: \(elapsedMls) mls")
            }
        }
    }
}
