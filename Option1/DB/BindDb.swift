import Foundation
import SwiftData

@Model
class BindDb {
    
    @Attribute(.unique) var id: UUID
    var key: String
    var workspaceId: UUID?
    var bundle: String
    var substring: String
    
    init(id: UUID, key: String, workspaceId: UUID?, bundle: String, substring: String) {
        self.id = id
        self.key = key
        self.workspaceId = workspaceId
        self.bundle = bundle
        self.substring = substring
    }
    
    @MainActor
    func delete() {
        DB.modelContainer.mainContext.delete(self)
        DB.save()
    }
    
    ///
    
    @MainActor
    static func getAll() -> [BindDb] {
        try! DB.modelContainer.mainContext.fetch(FetchDescriptor<BindDb>())
    }
    
    @MainActor
    static func insert(
        key: String,
        workspaceDb: WorkspaceDb?,
        bundle: String,
        substring: String,
    ) {
        DB.modelContainer.mainContext.insert(
            BindDb(
                id: UUID(),
                key: key,
                workspaceId: workspaceDb?.id,
                bundle: bundle,
                substring: substring,
            )
        )
        DB.save()
    }
}
