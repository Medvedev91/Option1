import SwiftUI
import SwiftData

@main
struct Option1App: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            AppScreen()
        }
        .modelContainer(for: [KvDb.self, WorkspaceDb.self])
        .commands {
            // Disable creating new window by Command + N
            CommandGroup(replacing: .newItem) {}
        }
    }
}
