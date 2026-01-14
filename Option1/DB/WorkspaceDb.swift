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
    func updateName(_ newName: String) {
        name = newName
        DB.save()
    }
    
    @MainActor
    func updateSort(_ newSort: Int) {
        sort = newSort
        DB.save()
    }
    
    @MainActor
    func deleteWithDependencies() {
        BindDb.selectAll().filter { $0.workspaceId == id }.forEach { $0.delete() }
        DB.modelContainer.mainContext.delete(self)
        DB.save()
    }
    
    ///
    
    @MainActor
    static func selectAll() -> [WorkspaceDb] {
        try! DB.modelContainer.mainContext.fetch(FetchDescriptor<WorkspaceDb>())
    }
    
    @MainActor
    static func insert() -> WorkspaceDb {
        let lastSort: Int = selectAll().max { $0.sort < $1.sort }?.sort ?? 0
        let nextSort: Int = lastSort + 1
        let workspaceDb = WorkspaceDb(
            id: UUID(),
            name: "Workspace #\(nextSort)",
            date: Date.now,
            sort: nextSort,
        )
        DB.modelContainer.mainContext.insert(workspaceDb)
        DB.save()
        return workspaceDb
    }
}
