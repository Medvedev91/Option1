import Foundation

class SystemInfo {
    
    static func getBuildOrNil() -> Int? {
        guard let bundleString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return nil
        }
        return Int(bundleString)
    }
    
    static func getAppVersionOrNil() -> String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    static func getOsVersion() -> String {
        let cv = ProcessInfo.processInfo.operatingSystemVersion
        return "\(cv.majorVersion).\(cv.minorVersion).\(cv.patchVersion)"
    }
    
    static func getModelIdentifierOrNil() -> String? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice"),
        )
        var modelIdentifier: String?
        if let modelData = IORegistryEntryCreateCFProperty(
            service, "model" as CFString, kCFAllocatorDefault, 0,
        ).takeRetainedValue() as? Data {
            modelIdentifier = String(data: modelData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
        }
        
        IOObjectRelease(service)
        return modelIdentifier
    }
}
