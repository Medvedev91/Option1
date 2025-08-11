import SwiftData

// https://fatbobman.com/en/snippet/fix-synchronization-issues-for-macos-apps-using-core-dataswiftdata/

struct DB {
    
    static let modelContainer: ModelContainer = {
        let schema = Schema([KvDb.self, WorkspaceDb.self, BindDb.self])
        let configuration = ModelConfiguration(cloudKitDatabase: .none)
        return try! ModelContainer(for: schema, configurations: configuration)
    }()
    
    @MainActor
    static func save() {
        try! modelContainer.mainContext.save()
    }
}
