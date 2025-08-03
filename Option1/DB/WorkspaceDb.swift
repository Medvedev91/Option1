import Foundation
import SwiftData

@Model
class WorkspaceDb {
    
    @Attribute(.unique) var id: UUID
    var name: String
    var date: Date
    var sort: Int
    
    init(id: UUID, name: String, date: Date, sort: Int) {
        self.id = id
        self.name = name
        self.date = date
        self.sort = sort
    }
}
