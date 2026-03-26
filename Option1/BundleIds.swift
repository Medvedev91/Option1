// todo Visual Studio
//
// При добавлении учитывать UI в WorkspaceBindView.swift
//
class BundleIds {
    
    // Apple
    static let Finder = "com.apple.finder"
    static let TextEdit = "com.apple.TextEdit"
    static let Pages = "com.apple.Pages"
    static let Numbers = "com.apple.Numbers"
    static let Xcode = "com.apple.dt.Xcode"
    // JetBrains
    static let IntelliJ = "com.jetbrains.intellij"
    static let PhpStorm = "com.jetbrains.PhpStorm"
    static let WebStorm = "com.jetbrains.WebStorm"
    static let PyCharm = "com.jetbrains.pycharm"
    static let RustRover = "com.jetbrains.rustrover"
    static let GoLand = "com.jetbrains.goland"
    static let dotMemory = "com.jetbrains.dotmemory"
    static let dotTrace = "com.jetbrains.dottrace"
    static let DataSpell = "com.jetbrains.dataspell"
    static let DataGrip = "com.jetbrains.datagrip"
    static let CLion = "com.jetbrains.CLion"
    static let Rider = "com.jetbrains.rider"
    static let RubyMine = "com.jetbrains.rubymine"
    static let SpaceDesktop = "com.jetbrains.space.desktop"
    static let MPS = "com.jetbrains.mps"
    static let Gateway = "com.jetbrains.gateway"
    static let Air = "com.jetbrains.air"
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
            WebStorm,
            PyCharm,
            RustRover,
            GoLand,
            dotMemory,
            dotTrace,
            DataSpell,
            DataGrip,
            CLion,
            Rider,
            RubyMine,
            SpaceDesktop,
            MPS,
            Gateway,
            Air,
            AndroidStudio,
        ].contains(bundle)
    }
}
