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
    func selectAppNameOrNil() -> String? {
        AppDb.selectAll().first(where: { $0.bundle == self.bundle })?.name
    }
    
    @MainActor
    func updateBundleAndSubstring(bundle: String, substring: String) {
        self.bundle = bundle
        self.substring = substring
        DB.save()
    }
    
    @MainActor
    func delete() {
        DB.modelContainer.mainContext.delete(self)
        DB.save()
    }
    
    //
    // For Transaction
    
    @MainActor
    static func deleteAll_ForTransaction() {
        selectAll().forEach {
            DB.modelContainer.mainContext.delete($0)
        }
    }
    
    @MainActor
    static func insert_ForTransaction(id: UUID, key: String, workspaceId: UUID?, bundle: String, substring: String) {
        DB.modelContainer.mainContext.insert(BindDb(
            id: id,
            key: key,
            workspaceId: workspaceId,
            bundle: bundle,
            substring: substring,
        ))
    }
    
    ///
    
    @MainActor
    static func selectAll() -> [BindDb] {
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
