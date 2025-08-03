import SwiftUI

@main
struct Option1App: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainScreen()
                .frame(minWidth: 350, minHeight: 350)
        }
        .windowResizability(.contentSize)
    }
}
