import SwiftUI
import SwiftData

// https://fatbobman.com/en/snippet/fix-synchronization-issues-for-macos-apps-using-core-dataswiftdata/

@main
struct Option1App: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    private let modelContainer: ModelContainer = {
        let schema = Schema([KvDb.self, WorkspaceDb.self])
        let configuration = ModelConfiguration(cloudKitDatabase: .none)
        return try! ModelContainer(for: schema, configurations: configuration)
    }()
    
    var body: some Scene {
        WindowGroup {
            AppScreen()
        }
        .modelContainer(modelContainer)
        .commands {
            // Disable creating new window by Command + N
            CommandGroup(replacing: .newItem) {}
        }
    }
}
