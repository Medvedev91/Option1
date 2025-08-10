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
        let maxSort: Int = workspacesDb.max { $0.sort < $1.sort }?.sort ?? 0
        let nextSort: Int = maxSort + 1
        modelContext.insert(
            WorkspaceDb(
                id: UUID(),
                name: "Workspace #\(nextSort)",
                date: Date.now,
                sort: nextSort,
            )
        )
        try! modelContext.save()
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
            workspaceDb.sort = idx
        }
        try! modelContext.save()
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
                        modelContext.delete(workspaceDb)
                        try! modelContext.save()
                    },
                    label: {
                        Text("Delete")
                            .foregroundColor(.red)
                    },
                )
            }
    }
}
