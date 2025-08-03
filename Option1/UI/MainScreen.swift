import SwiftUI
import SwiftData
import Cocoa

struct MainScreen: View {
    
    @Environment(\.modelContext) var modelContext
    
    @Query private var workspacesDb: [WorkspaceDb] = []
    
    @State private var axuiElements: [AXUIElement] = []
    @State private var focusedWindow: AXUIElement? = nil
    
    private let timer1s = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var isPermissionGranted = isAccessibilityGranted(showDialog: false)
    
    var body: some View {
        VStack {
            
            if !isPermissionGranted {
                PermissionView()
            } else {
                
                Button("Debug App in 3 Seconds") {
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
                
                Section("Workspaces") {
                    ForEach(workspacesDb) { workspaceDb in
                        Text(workspaceDb.name)
                            .onTapGesture {
                                modelContext.delete(workspaceDb)
                            }
                    }
                }
                
                Button("New Workspace") {
                    modelContext.insert(WorkspaceDb(id: UUID(), name: "New Workspace", date: Date.now, sort: 1))
                }
            }
        }
        .padding()
        .onReceive(timer1s) { _ in
            isPermissionGranted = isAccessibilityGranted(showDialog: false)
        }
        .onChange(of: workspacesDb, initial: true) { _, workspacesDb in
            MenuManager.setWorkspacesDb(workspacesDb)
        }
    }
}
