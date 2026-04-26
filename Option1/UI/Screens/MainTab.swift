import SwiftUI

struct MainTab: View {
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                AppText("Bind shortcuts like **`⌥-1`**, **`⌥-2`** to apps you need.")
                
                AppText("Press **`⌥-1`** to open Safari, **`⌥-2`** to Calendar. Customize it.")
                
                Image("readme_basics")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500)
                
                MyTitle("Open files, projects, folders, websites.")
                
                Image("readme_examples")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500)
                
                MyTitle("Set up workspaces.")

                Image("readme_workspaces")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 640)
                
                AppText("Switch workspace with menu bar:")
                
                Image("readme_menu")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500)
                    .padding(.top, 8)
                
                MyTitle("⌥-Tab.")
                    .padding(.top, 32)
                
                AppText("An addition to built-in **`⌘-Tab`**, because macOS opens apps, not windows.")
                
                Image("readme_option_tab")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: AppText.MAX_WIDTH)
                    .padding(.top, 8)
                
                MyTitle("P.S.")
                    .font(.largeTitle)
                    .padding(.top, 32)
                
                AppText("I call it pragmatic because I focus on the features I miss in macOS. It is not a replacement but an addition to the built-in macOS window management:\n• supports multiple displays ✅\n• supports built-in macOS desktops ✅\n• supports full-screen windows ✅")
                
                AppText("Best regards,\n[Ivan](https://github.com/Medvedev91)")
                
                HStack {
                    Spacer()
                }
                .frame(height: 24)
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
