import SwiftUI
import SwiftData

@main
struct Option1App: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            AppScreen()
                .frame(width: 350, height: 400)
        }
        .modelContainer(for: [KvDb.self, WorkspaceDb.self])
        .windowResizability(.contentSize)
        .commands {
            // Disable creating new window by Command + N
            CommandGroup(replacing: .newItem) {}
        }
    }
}
