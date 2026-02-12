import SwiftUI

struct MainTab: View {
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                MyText("The idea - binding shortcuts like **`⌥-1`**, **`⌥-2`** to windows you need.")
                
                MyText("Press **`⌥-1`** to open Safari, **`⌥-2`** to open Calendar. Customize it.")
                
                Image("readme_basics")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 480)
                
                MyTitle("Windows")
                    .font(.largeTitle)
                
                MyText("Manage apps with multiple open windows. Like multiple open Word documents or Xcode projects.")
                    .padding(.top, 4)
                
                MyText("Let's say we have two windows for one app, like two Xcode projects. We cannot open the window we need with built-in **`⌘-Tab`** because macOS opens apps, not windows. Let's solve this with Option1.")
                
                MyText("Look at the screenshot:\n• for **`⌥-3`** I bind **Xcode** with **Option1** title substring,\n• for **`⌥-4`** I bind **Xcode** with **timeto.me** title substring.")
                
                MyText("This means **`⌥-3`** opens **Xcode** window with **Option1** in the title, and **`⌥-4`** with **timeto.me**. Solved!")
                
                Image("readme_windows")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 800)
                    .padding(.top, 12)
                
                MyTitle("Workspaces")
                    .font(.largeTitle)
                    .padding(.top, 30)
                
                MyText("Set up sets of shortcuts for different projects.")
                    .padding(.top, 4)
                
                MyText("I work on two projects: **Option1** and **timeto.me**. I got used to press **`⌥-3`** to open **Xcode**. This means when I work on **Option1** I want **`⌥-3`** opens **Xcode - Option1**, but when I work on **timeto.me** the same **`⌥-3`** should open **Xcode - timeto.me**.")
                
                MyText("The same way, depending on the project I'm working on, **`⌥-4`** should open the right **IntelliJ IDEA** window.")
                
                MyText("This is how I set up two workspaces:")
                
                Image("readme_workspaces")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 600)
                
                MyText("To switch between workspaces, use menu bar:")
                
                Image("readme_menu")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500)
                    .padding(.top, 8)
                
                MyTitle("P.S.")
                    .font(.largeTitle)
                    .padding(.top, 30)
                
                MyText("I call it pragmatic because I focus on the features I miss in macOS. It is not a replacement but an addition to the built-in macOS window management:\n• supports multiple displays ✅\n• supports built-in macOS desktops ✅\n• supports full-screen windows ✅")
                
                MyText("Best regards,\nIvan")
                
                VStack {}
                    .frame(height: 10)
                
                Divider()
                    .padding(.vertical)
                
                SparkleButtonView()
            }
            .padding()
        }
        .navigationTitle("Option1 - Pragmatic Window Manager")
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

private struct MyText: View {
    
    private let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(try! AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace),
        ))
        .font(.system(size: 14))
        .lineSpacing(4)
        .textAlign(.leading)
        .frame(maxWidth: 700)
    }
}
