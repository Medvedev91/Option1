import AppKit
import SwiftUI
import SwiftData

// todo example
// https://medium.com/@clyapp/customizing-swiftui-settings-window-on-macos-4c47d0060ee4

struct SettingsScreen: View {
    
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.modelContext) private var modelContext
    
    @Query private var workspacesDb: [WorkspaceDb] = []
    
    @State private var axuiElements: [AXUIElement] = []
    @State private var focusedWindow: AXUIElement? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                Text("Bind Window - Option + Shift + 1 .. 9")
                    .padding(.top, 4)
                
                Text("Focus Window - Option + 1 .. 9")
                    .padding(.top, 4)
                
                Divider()
                    .padding(.vertical)
                
                Text("Workspaces")
                    .font(.system(size: 18, weight: .bold))
                
                Text("Shared (default)")
                    .padding(.top, 4)
                
                ForEach(workspacesDb) { workspaceDb in
                    Text(workspaceDb.name)
                        .onTapGesture {
                            modelContext.delete(workspaceDb)
                        }
                }
                
                Button("New") {
                    modelContext.insert(WorkspaceDb(id: UUID(), name: "New Workspace", date: Date.now, sort: 1))
                }
                .padding(.top, 8)
                
                Divider()
                    .padding(.vertical)
                
                Button("Debug") {
                    Task {
                        try await Task.sleep(nanoseconds: 3_000_000_000)
                        let axuiElements = try! WindowsManager.getWindowsForActiveApplicationOrNil() ?? []
                        self.axuiElements = axuiElements
                        self.focusedWindow = try! WindowsManager.getFocusedWindowOrNil()
                    }
                }
                
                if let focusedWindow = focusedWindow {
                    Button("Focused \(try! focusedWindow.title()) \(focusedWindow.id())") {
                        try! WindowsManager.focusWindow(axuiElement: focusedWindow)
                    }
                }
                
                ForEach(axuiElements, id: \.self) { axuiElement in
                    Button("Run \(try! axuiElement.title()) \(axuiElement.id())") {
                        try! WindowsManager.focusWindow(axuiElement: axuiElement)
                    }
                }
                
                SparkleButtonView()
                    .padding(.top, 10)
                
                Button("Close Window") {
                    dismissWindow()
                }
                .padding(.top, 10)
                
            }
            .padding()
        }
    }
}
