import AppKit

@MainActor
struct OptionTabFavoriteUi {
    
    let jumpKey: OptionTabJumpKey
    let favoriteDb: FavoriteDb
    let onClick: () -> Void
    
    var appDb: AppDb? {
        favoriteDb.selectAppDbOrNil()
    }
    
    var title: String {
        favoriteDb.buildUiTitle()
    }
    
    var icon: NSImage? {
        appDb?.getIcon()
    }
}
