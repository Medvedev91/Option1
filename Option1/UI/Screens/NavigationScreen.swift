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
                        .onMove { from, to in
                            moveWorkspace(from: from, to: to)
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
    
    private func moveWorkspace(from: IndexSet, to: Int) {
        var sortedWorkspacesDb = workspacesDb
        from.forEach { fromIdx in
            // Fix crash if single item
            // and ignore same position
            if fromIdx == to {
                return
            }
            let newFromIdx = fromIdx
            let newToIdx = (fromIdx > to ? to : (to - 1))
            sortedWorkspacesDb.swapAt(newFromIdx, newToIdx)
        }
        sortedWorkspacesDb.enumerated().forEach { idx, workspaceDb in
            workspaceDb.updateSort(idx)
        }
    }
}

private enum Tab: Hashable {
    case main
    case workspaces
    case settings
    case workspace(workspaceDb: WorkspaceDb?)
}
