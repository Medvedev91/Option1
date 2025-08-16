import SwiftUI
import SwiftData

struct WorkspacesTabView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \WorkspaceDb.sort) private var workspacesDb: [WorkspaceDb] = []
    
    var body: some View {
        List {
            ForEach(workspacesDb) { workspaceDb in
                WorkspaceItemView(workspaceDb: workspaceDb)
            }
            .onMove { from, to in
                moveWorkspace(from: from, to: to)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Workspaces")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Workspace") {
                    newWorkspace()
                }
                .buttonStyle(.link)
            }
        }
    }
    
    private func newWorkspace() {
        WorkspaceDb.insert()
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

private struct WorkspaceItemView: View {
    
    @Bindable var workspaceDb: WorkspaceDb

    ///
    
    @Environment(\.modelContext) private var modelContext
    
    @FocusState private var focused: Bool

    var body: some View {
        TextField("Workspace Name", text: $workspaceDb.name)
            .listRowInsets(.init())
            .autocorrectionDisabled()
            .focused($focused, equals: true)
            .padding(.vertical, 8)
            .onTapGesture {
                focused = true
            }
            .contextMenu {
                Button(
                    action: {
                        workspaceDb.deleteWithDependencies()
                    },
                    label: {
                        Text("Delete")
                            .foregroundColor(.red)
                    },
                )
            }
    }
}
