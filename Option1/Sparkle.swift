//
// Sparkle https://sparkle-project.org/documentation/
//
// Release Documentation
// - Bump app version,
// - Xcode: Product -> Archive -> Distribute App -> Direct Distribution;
// - Wait for Ready to distribute -> Export App. Save to Download with New Folder -> "Option1";
// - Open Terminal app, cd ~/Downloads/Option1; run: create-dmg 'Option1.app', don't care about signed error;
// - Rename new file to Option1.dmg, remove Option1.app file from Option1 folder.
// - Right click on Sparkle in project navigator: Show in Finder;
// - Go to parent folder: Go -> Enclosing Folder -> Artifacts -> sparkle -> Sparkle -> bin;
// - Open Terminal app, move generate_appcast file to terminal, add ~/Downloads/Option1, run;
// - Upload appcast.xml and Option1.dmg to option1.io root.
//

import Sparkle

let sparkleController = SPUStandardUpdaterController(
    startingUpdater: true,
    updaterDelegate: nil,
    userDriverDelegate: nil,
)
