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
    
    @MainActor
    func deleteWithDependencies() {
        BindDb.selectAll().filter { $0.workspaceId == id }.forEach { $0.delete() }
        DB.modelContainer.mainContext.delete(self)
        DB.save()
    }
    
    ///
    
    @MainActor
    static func getAll() -> [WorkspaceDb] {
        try! DB.modelContainer.mainContext.fetch(FetchDescriptor<WorkspaceDb>())
    }
}
