import SwiftUI
import SwiftData

// todo
// 3. Disabling Sidebar Width Resizing
// https://medium.com/@clyapp/customizing-swiftui-settings-window-on-macos-4c47d0060ee4

struct NavigationScreen: View {
    
    @State private var tab: Tab = .main
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    @Query(sort: \WorkspaceDb.sort) private var workspacesDb: [WorkspaceDb]
    
    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            sidebar: {
                List(selection: $tab) {
                    
                    Label("Option 1", systemImage: "option")
                        .tag(Tab.main)
                    Label("Workspaces", systemImage: "rectangle.stack")
                        .tag(Tab.workspaces)
                    Label("Settings", systemImage: "gearshape")
                        .tag(Tab.settings)
                    
                    Section("Workspaces") {
                        Label("Shared", systemImage: "rectangle.on.rectangle")
                            .tag(Tab.workspace(workspaceDb: nil))
                        ForEach(workspacesDb) { workspaceDb in
                            Label(workspaceDb.name, systemImage: "rectangle")
                                .tag(Tab.workspace(workspaceDb: workspaceDb))
                        }
                    }
                    .collapsible(false)
                }
                .listStyle(.sidebar)
                .frame(minWidth: 200)
            },
            detail: {
                switch tab {
                case .main:
                    MainTabView()
                case .workspaces:
                    WorkspacesTabView()
                case .settings:
                    SettingsTabView()
                case .workspace(let workspaceDb):
                    WorkspaceScreen(workspaceDb: workspaceDb)
                }
            }
        )
    }
}

private enum Tab: Hashable {
    case main
    case workspaces
    case settings
    case workspace(workspaceDb: WorkspaceDb?)
}
