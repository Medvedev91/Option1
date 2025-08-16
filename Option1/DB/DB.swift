import Foundation
import SwiftData

// https://fatbobman.com/en/snippet/fix-synchronization-issues-for-macos-apps-using-core-dataswiftdata/

struct DB {
    
    // https://gist.github.com/Medvedev91/6d797561326c56e7467ed060b9f6e1ba
    static let modelContainer: ModelContainer = {
        #if DEBUG
            let folder = "Option1Debug"
        #else
            let folder = "Option1"
        #endif
        let fileURL = URL.applicationSupportDirectory.appending(path: "\(folder)/SwiftData.store")
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
