import SwiftUI
import SwiftData

struct NavigationScreen: View {
    
    @State private var tab: Tab = .main
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    @Query(sort: \WorkspaceDb.sort) private var workspacesDb: [WorkspaceDb]
    
    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            sidebar: {
                VStack(spacing: 0) {

                    List(selection: $tab) {
                        
                        Label("Option 1", systemImage: "option")
                            .tag(Tab.main)
                        
                        Section("Workspaces") {
                            Label("Shared", systemImage: "rectangle.on.rectangle")
                                .tag(Tab.workspace(workspaceDb: nil))
                            ForEach(workspacesDb) { workspaceDb in
                                WorkspaceItemView(workspaceDb: workspaceDb)
                            }
                            .onMove { from, to in
                                moveWorkspace(from: from, to: to)
                            }
                        }
                        .collapsible(false)
                    }
                    .listStyle(.sidebar)
                    .frame(minWidth: 200)
                    
                    Spacer()
                    
                    Divider()
                    
                    HStack {
                        Button(
                            action: {
                                WorkspaceDb.insert()
                            },
                            label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 13))
                            }
                        )
                        .buttonStyle(.plain)
                        .padding(.leading, 8)
                        .opacity(0.8)
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                }
            },
            detail: {
                switch tab {
                case .main:
                    MainTabView()
                case .workspace(let workspaceDb):
                    WorkspaceScreen(workspaceDb: workspaceDb)
                        .id("WorkspaceScreen \(workspaceDb?.id.uuidString ?? "")")
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
    case workspace(workspaceDb: WorkspaceDb?)
}

private struct WorkspaceItemView: View {
    
    let workspaceDb: WorkspaceDb
    
    ///
    
    @State private var isDeleteConfirmationPresented = false
    
    var body: some View {
        
        Label(workspaceDb.name, systemImage: "rectangle")
            .tag(Tab.workspace(workspaceDb: workspaceDb))
            .contextMenu {
                Button(
                    action: {
                        isDeleteConfirmationPresented = true
                    },
                    label: {
                        Text("Delete")
                            .foregroundColor(.red)
                    },
                )
            }
            .confirmationDialog(
                "Are you sure to delete \(workspaceDb.name)?",
                isPresented: $isDeleteConfirmationPresented,
            ) {
                Button("Yes") {
                    workspaceDb.deleteWithDependencies()
                }
                .keyboardShortcut(.defaultAction)
                
                Button("No", role: .cancel) {}
            }
    }
}
