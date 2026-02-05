import Foundation

func getModelIdentifier() -> String? {
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
