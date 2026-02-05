import Foundation

func getOsVersion() -> String {
    let cv = ProcessInfo.processInfo.operatingSystemVersion
    return "\(cv.majorVersion).\(cv.minorVersion).\(cv.patchVersion)"
}
