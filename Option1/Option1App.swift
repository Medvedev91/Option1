import SwiftUI
import SwiftData

@main
struct Option1App: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            AppScreen()
        }
        .modelContainer(DB.modelContainer)
        .commands {
            // Disable creating new window by Command + N
            CommandGroup(replacing: .newItem) {}
        }
    }
}
