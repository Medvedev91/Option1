import Combine

class FavoriteTabUtils: ObservableObject {

    static let instance = FavoriteTabUtils()
    
    @Published var needToShow: Bool = false
}
