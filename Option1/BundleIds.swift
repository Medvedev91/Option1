// todo Apple Pages, Tables...
// todo Jetbrain IDE's
// todo Visual Studio
//
// При добавлении учитывать UI в WorkspaceBindView.swift
//
class BundleIds {
    
    // Apple
    static let Finder = "com.apple.finder"
    static let TextEdit = "com.apple.TextEdit"
    static let Pages = "com.apple.Pages"
    static let Xcode = "com.apple.dt.Xcode"
    // JetBrains
    static let IntelliJ = "com.jetbrains.intellij"
    static let PhpStorm = "com.jetbrains.PhpStorm"
    static let PyCharm = "com.jetbrains.pycharm"
    static let RustRover = "com.jetbrains.rustrover"
    static let GoLand = "com.jetbrains.goland"
    static let AndroidStudio = "com.google.android.studio"
    // Microsoft
    static let MicrosoftWord = "com.microsoft.Word"
    static let MicrosoftExcel = "com.microsoft.Excel"
    static let MicrosoftPowerPoint = "com.microsoft.Powerpoint"
    
    static func isOpenByShellWithNewWindow(_ bundle: String) -> Bool {
        [
            // JetBrains
            IntelliJ,
            PhpStorm,
            PyCharm,
            RustRover,
            GoLand,
            AndroidStudio,
        ].contains(bundle)
    }
}
