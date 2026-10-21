import SwiftUI

struct MainTab: View {
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                MyTitle("Two new features for macOS:")
                
                AppText(
                    "**1.** Open **apps** with shortcuts, like **`⌥-1`** for Chrome, **`⌥-2`** for Slack;",
                    highlighted: ["⌥-1", "⌥-2"],
                )
                
                AppText(
                    "**2.** Open **projects** with shortcuts, like **`⌥-3`** for **`Option1.xcodeproj`** in Xcode. Any app.",
                    highlighted: ["⌥-3", "Xcode -> Option1.xcodeproj"],
                )
                
                MyTitle("Option1 - Window Manager for macOS")
                    .padding(.top, 32)
                
                AppText("I built this app to add features **I miss** in macOS. Now, I will share how **I manage** windows in macOS.")
                
                MyTitle("1. Built-in ⌘-Tab.")
                    .padding(.top, 32)
                
                AppText(
                    "To switch windows, I usually use the built-in **`⌘-Tab`**. Like always, nothing new.",
                    highlighted: ["⌘-Tab"],
                )
                
                MyTitle("2. Shortcuts for the most used apps.")
                    .padding(.top, 32)
                
                AppText("For apps that I use most often, like web browser or messaging app - I bind shortcuts like this:")
                
                Image("readme_basics")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500)
                
                MyTitle("3. Shortcuts for projects, files, websites...")
                    .padding(.top, 32)
                
                AppText("This is my favorite feature.")
                
                AppText(
                    "**Example:** As a **Option1** developer, I often open **`Option1.xcodeproj`** project in Xcode. What I did:",
                    highlighted: ["~/dev/Option1/Option1.xcodeproj"],
                )
                
                Image("readme_example_xcode")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500)
                
                AppText(
                    "Now, **I don't care** if the project is open or closed. **I just press** **`⌥-8`**. I will always switch to the project I need. If the app or project is closed - it opens, otherwise - gets focus.",
                    highlighted: ["⌥-8"],
                )
                
                AppText(
                    "It's especially useful when we have many Xcode projects open. Because built-in **`⌘-Tab`** switch apps, not projects or windows.",
                    highlighted: ["⌘-Tab"],
                )
                
                AppText("Works with any app. **More examples:**")
                
                Image("readme_examples")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500)
                
                AppText(
                    "Note that **`⌥-0`** not just opens Google Chrome like **`⌥-1`**, but also opens a new tab with **google.com**.",
                    highlighted: ["⌥-0", "⌥-1"],
                )

                MyTitle("4. Full-screen mode.")
                    .padding(.top, 32)
                
                AppText("Since we have quick access to any app or window with **shortcuts for projects,** I prefer to open most apps in full-screen mode.")
                
                AppText("This makes the main desktop clean and let us take advantage of every inch of the screen. Especially well for professional software.")
                
                AppText("To stay fully focused, I prefer to hide the **Menu Bar** for full-screen windows in **System Settings:**")
                
                Image("readme_in_full_screen_only")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 600)
                
                MyTitle("5. Built-in desktops + \"Assign To This Desktop\".")
                    .padding(.top, 32)
                
                AppText("There is a built-in feature that not many people know about.")
                
                AppText("**Example:** I use a separate desktop with windows for my work: **Slack** and **Firefox** - **Desktop 2:**")
                
                Image("readme_desktops")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                AppText(
                    "Since I bind **`⌥-2`** for Slack, I want Slack to always open on **Desktop 2**. For this, I switch to **Desktop 2** and assign **Slack** to **This Desktop:**",
                    highlighted: ["⌥-2"],
                )
                
                Image("readme_assign_to")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: AppText.MAX_WIDTH)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                AppText(
                    "Now, **I don't care** if **Slack** is open or closed. **I just press** **`⌥-2`**. I will always move to **Desktop 2** where **Slack** will be open and focused.",
                    highlighted: ["⌥-2"],
                )
                
                AppText("Since I have shortcuts for the apps I use most often, I prefer to hide the **Dock:**")
                
                Image("readme_hide_dock")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 600)
                
                MyTitle("6. Workspaces.")
                    .padding(.top, 32)
                
                AppText(
                    "I'm working on two projects: **Option1** and **timeto.me**. **I don't want** to bind different shortcuts for each project, **I want** **`⌥-8`** to always open Xcode project I'm currently working on.",
                    highlighted: ["⌥-8"],
                )
                
                AppText("To make this possible, I created two workspaces: **Option1** and **timeto.me:**")
                
                Image("readme_workspaces")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: AppText.MAX_WIDTH)
                
                AppText(
                    "Note that **`⌥-1`** and **`⌥-2`** still work from **Shared**.",
                    highlighted: ["⌥-1", "⌥-2"],
                )
                
                AppText("To switch the workspace use menu bar:")
                
                Image("readme_menu")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500)
                
                MyTitle("One more thing. ⌥-Tab.")
                    .padding(.top, 50)
                
                AppText(
                    "An addition to built-in **`⌘-Tab`**. Especially useful when you need to switch a window for the app, because built-in ⌘-Tab switch apps, not windows.",
                    highlighted: ["⌘-Tab"],
                )
                
                Image("readme_option_tab")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: AppText.MAX_WIDTH)
                    .padding(.top, 8)
                
                AppText(
                    "**`⌥-Tab`** provides a few additional options:\n• **Pinned apps** to the top of the list;\n• **Double Option** displays a list of windows. Useful to check window badges;\n• **⌥-\\`** and **⌘-\\`** only jumps to windows with badges;\n• **Sorting windows** by apps, history, or special **JK mode**;\n• **Vim-inspired JK mode** is a combination of Apps and History. Press **`⌥-Tab`** to Apps mode, **`⌥-J`** to History;\n• **`⌥-(A-Z)`** for windows. **WARNING** If you need these shortcuts in other apps, turn this off in settings;\n• **Favourites.**",
                    highlighted: ["⌥-Tab", "⌥-`", "⌘-`", "⌥-J", "⌥-(A-Z)"],
                )
                
                AppText(
                    "To be honest, I don't use **`⌥-Tab`** very often. But sometimes it's just indispensable.",
                    highlighted: ["⌥-Tab"],
                )
                
                MyTitle("Post Scriptum")
                    .font(.largeTitle)
                    .padding(.top, 32)
                
                AppText("Crafting this app I focused on the features I missed in macOS. It is not a replacement but an addition to the built-in macOS window management:\n• supports multiple displays ✅\n• supports built-in macOS desktops ✅\n• supports full-screen windows ✅")
                
                IvanView(imageSize: 56, fontWeight: .semibold)
                    .padding(.top, 28)
                
                HStack {
                    Spacer()
                }
                .frame(height: 24)
            }
            .padding()
        }
        .navigationTitle("Option1 - Window Manager for macOS")
    }
}

private struct MyTitle: View {
    
    private let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 30, weight: .semibold))
    }
}
