import SwiftData

@Model
class KvDb {
    
    @Attribute(.unique) var key: String
    var value: String
    
    init (key: String, value: String) {
        self.key = key
        self.value = value
    }
}
