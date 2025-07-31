//
// Sparkle https://sparkle-project.org/documentation/
//
// Release Documentation
// - Bump app version,
// - Xcode: Product -> Archive -> Distribute App -> Direct Distribution;
// - Wait for Ready to distribute -> Export App. Save to Download with New Folder -> "Option1";
// - Open Disk Utility app, New Image -> Image from Folder -> create .dmg from Option1 folder;
// - Move Option1.dmg to Option1 folder, remove Option1 application file from Option1 folder.
// - Right click on Sparkle in project navigator: Show in Finder;
// - Go to parent folder: Go -> Enclosing Folder -> Artifacts -> sparkle -> Sparkle -> bin;
// - Open Terminal app, move generate_appcast file to terminal, add ~/Downloads/Option1, run;
// - Upload appcast.xml and Option1.dmg to option1.io root.
//

import SwiftUI
import Sparkle

var sparkleController: SPUStandardUpdaterController!

@main
struct Option1App: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        sparkleController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
