import SwiftUI
import SwiftData

@main
struct Option1App: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainScreen()
                .frame(width: 350, height: 400)
        }
        .modelContainer(dbContainer)
        .windowResizability(.contentSize)
        .commands {
            // Disable creating new window by Command + N
            CommandGroup(replacing: .newItem) {}
        }
    }
}
