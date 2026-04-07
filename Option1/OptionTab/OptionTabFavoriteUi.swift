import AppKit
import HotKey

@MainActor
struct OptionTabFavoriteUi {
    
    let key: Key
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
