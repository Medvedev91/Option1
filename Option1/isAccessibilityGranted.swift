import Cocoa

// https://stackoverflow.com/a/79011074 robotsquidward's answer
func isAccessibilityGranted(showDialog: Bool) -> Bool {
    let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
    let options = [checkOptPrompt: showDialog]
    return AXIsProcessTrustedWithOptions(options as CFDictionary?)
}
