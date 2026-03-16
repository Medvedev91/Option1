class BundleIds {
    
    static let Finder = "com.apple.finder"
    static let Xcode = "com.apple.dt.Xcode"
    // JetBrains
    static let IntelliJ = "com.jetbrains.intellij"
    // Microsoft
    static let MicrosoftWord = "com.microsoft.Word"
    
    static func isOpenByShellNoNewWindow(_ bundle: String) -> Bool {
        [Finder, MicrosoftWord].contains(bundle)
    }
    
    static func isOpenByShellWithNewWindow(_ bundle: String) -> Bool {
        [IntelliJ].contains(bundle)
    }
}
