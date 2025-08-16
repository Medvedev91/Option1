import SwiftUI
import SwiftData
import Cocoa

struct AppScreen: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \WorkspaceDb.sort) private var workspacesDb: [WorkspaceDb]
    private var workspacesObserver: Int {
        MenuManager.setWorkspacesDb(workspacesDb)
        return 1
    }
    
    private let timer1s = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var isPermissionGranted = isAccessibilityGranted(showDialog: false)
    
    var body: some View {
        VStack {
            if !isPermissionGranted {
                PermissionView()
            } else {
                NavigationScreen()
            }
        }
        .onReceive(timer1s) { _ in
            isPermissionGranted = isAccessibilityGranted(showDialog: false)
        }
        .onChange(of: workspacesObserver) {
            // Not body needed. Just force workspacesObserver execution.
            // Just onChange(workspacesDb) ignores fields changes.
        }
    }
}
