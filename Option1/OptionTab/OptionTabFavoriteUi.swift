import AppKit

@MainActor
struct OptionTabFavoriteUi {
    
    let jumpKey: OptionTabJumpKey
    let favoriteDb: FavoriteDb
    let onClick: () -> Void
    
    let appDb: AppDb?
    let title: String
    let icon: NSImage?
    
    init(
        jumpKey: OptionTabJumpKey,
        favoriteDb: FavoriteDb,
        onClick: @escaping () -> Void,
    ) {
        self.jumpKey = jumpKey
        self.favoriteDb = favoriteDb
        self.onClick = onClick
        
        self.appDb = favoriteDb.selectAppDbOrNil()
        self.title = favoriteDb.buildUiTitle()
        self.icon = appDb?.getIcon()
    }
}
