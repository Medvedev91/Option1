import SwiftUI
import SwiftData
import Cocoa

struct MainScreen: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query private var workspacesDb: [WorkspaceDb] = []
    
    private let timer1s = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var isPermissionGranted = isAccessibilityGranted(showDialog: false)
    
    var body: some View {
        VStack {
            if !isPermissionGranted {
                PermissionView()
            } else {
                SettingsScreen()
            }
        }
        .onReceive(timer1s) { _ in
            isPermissionGranted = isAccessibilityGranted(showDialog: false)
        }
        .onChange(of: workspacesDb, initial: true) { _, workspacesDb in
            MenuManager.setWorkspacesDb(workspacesDb)
        }
    }
}
