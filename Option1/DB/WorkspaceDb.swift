import Foundation
import SwiftData

@Model
class WorkspaceDb {
    
    @Attribute(.unique) var id: UUID
    var name: String
    var date: Date
    var sort: Int
    
    var uniqString: String {
        "\(id)-\(name)-\(date)-\(sort)"
    }
    
    init(id: UUID, name: String, date: Date, sort: Int) {
        self.id = id
        self.name = name
        self.date = date
        self.sort = sort
    }
    
    // todo func delete with deps
    // todo func insert
    
    ///
    
    @MainActor
    static func getAll() -> [WorkspaceDb] {
        try! DB.modelContainer.mainContext.fetch(FetchDescriptor<WorkspaceDb>())
    }
}
