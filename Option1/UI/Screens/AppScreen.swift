import SwiftUI
import SwiftData
import Cocoa

struct AppScreen: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \WorkspaceDb.sort) private var workspacesDb: [WorkspaceDb]
    private var workspacesObserver: Int {
        MenuManager.instance.setWorkspacesDb(workspacesDb)
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

private var appLaunchObserver: Any? = nil
private var appTerminateObserver: Any? = nil

private func setupAppObservers() {
    if let appLaunchObserver = appLaunchObserver {
        NSWorkspace.shared.notificationCenter.removeObserver(appLaunchObserver)
    }
    appLaunchObserver = NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didLaunchApplicationNotification,
        object: nil,
        queue: OperationQueue.main,
    ) { (notification: Notification) in
        // https://developer.apple.com/documentation/appkit/nsworkspace/didLaunchApplicationNotification
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            reportApi("didLaunchApplicationNotification nil")
            return
        }
        // Тут нельзя использовать Task, по этому initialTaskOrDispatch = false.
        // После запуска приложения надо подождать для загрузки окон - initialDelaySeconds.
        AppObserver.shared.addObserver(app: app, initialTaskOrDispatch: false, initialDelaySeconds: 2)
    }
    
    if let appTerminateObserver = appTerminateObserver {
        NSWorkspace.shared.notificationCenter.removeObserver(appTerminateObserver)
    }
    appTerminateObserver = NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didTerminateApplicationNotification,
        object: nil,
        queue: OperationQueue.main,
    ) { (notification: Notification) in
        // https://developer.apple.com/documentation/appkit/nsworkspace/didactivateapplicationnotification
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            reportApi("didTerminateApplicationNotification nil")
            return
        }
        guard let bundle = app.bundleIdentifier else {
            reportApi("didTerminateApplicationNotification no bundle")
            return
        }
        CachedWindow.cleanByBundle(bundle)
    }
    
    AppObserver.shared.restart()
}
