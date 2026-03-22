import SwiftUI

struct MainTab: View {
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                AppText("Bind shortcuts like **`⌥-1`**, **`⌥-2`** to windows you need.")
                
                AppText("Press **`⌥-1`** to open Safari, **`⌥-2`** to open Calendar. Customize it.")
                
                Image("readme_basics")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500)
                
                AppText("Open files, projects, folders.")
                
                Image("readme_examples")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500)
                
                AppText("Set up workspaces.")

                Image("readme_workspaces")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 640)
                
                AppText("To switch between workspaces, use menu bar:")
                
                Image("readme_menu")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500)
                    .padding(.top, 8)
                
                MyTitle("P.S.")
                    .font(.largeTitle)
                    .padding(.top, 30)
                
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
