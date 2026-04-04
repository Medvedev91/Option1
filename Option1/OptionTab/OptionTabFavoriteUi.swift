import AppKit

@MainActor
struct OptionTabFavoriteUi {
    
    let favoriteDb: FavoriteDb
    
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
