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
        .onChange(of: isPermissionGranted, initial: true) { _, newValue in
            if newValue {
                setupAppObservers()
            }
        }
    }
}

///

var activateObserver: Any? = nil

private func setupAppObservers() {
    if let activateObserver = activateObserver {
        NSWorkspace.shared.notificationCenter.removeObserver(activateObserver)
    }
    activateObserver = NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didActivateApplicationNotification,
        object: nil,
        queue: OperationQueue.main,
    ) { (notification: Notification) in
        // https://developer.apple.com/documentation/appkit/nsworkspace/didactivateapplicationnotification
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            reportApi("didActivateApplicationNotification nil")
            return
        }
        AppObserver.shared.addObserver(app: app)
    }
    AppObserver.shared.restart()
}
