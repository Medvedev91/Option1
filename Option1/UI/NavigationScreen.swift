import SwiftUI

struct NavigationScreen: View {
    
    @State private var tab: Tab = .main
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
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
                }
            }
        )
    }
}

private enum Tab {
    case main
    case workspaces
    case settings
}
