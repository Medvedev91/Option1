import Combine

class DonationsAlertUtils: ObservableObject {
    
    @Published var needToShow = false
    
    ///
    
    static let instance = DonationsAlertUtils()
}
