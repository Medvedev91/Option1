import Foundation
import SwiftData

// https://fatbobman.com/en/snippet/fix-synchronization-issues-for-macos-apps-using-core-dataswiftdata/

struct DB {
    
    static let modelContainer: ModelContainer = {
        // https://gist.github.com/pdarcey/981b99bcc436a64df222cd8e3dd92871
        let bundle: String = Bundle.main.bundleIdentifier!
        let fileURL = URL.applicationSupportDirectory.appending(path: "\(bundle)/SwiftData.store")
        let schema = Schema([KvDb.self, WorkspaceDb.self, BindDb.self])
        let configuration = ModelConfiguration(
            "SwiftData",
            schema: schema,
            url: fileURL,
            cloudKitDatabase: .none,
        )
        return try! ModelContainer(for: schema, configurations: configuration)
    }()
    
    @MainActor
    static func save() {
        try! modelContainer.mainContext.save()
    }
}
