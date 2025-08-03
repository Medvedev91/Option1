import SwiftUI
import SwiftData

@main
struct Option1App: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainScreen()
                .frame(minWidth: 350, minHeight: 350)
        }
        .modelContainer(dbContainer)
        .windowResizability(.contentSize)
        .commands {
            // Disable creating new window by Command + N
            CommandGroup(replacing: .newItem) {}
        }
    }
}
