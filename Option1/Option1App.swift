//
// Sparkle docs https://sparkle-project.org/documentation/programmatic-setup/
//

import SwiftUI
import Sparkle

@main
struct Option1App: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // todo one line
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                ContentView()
                Button("startUpdater() old") {
                    updaterController.startUpdater()
                }
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}
