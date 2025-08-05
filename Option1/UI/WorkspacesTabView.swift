import SwiftUI
import SwiftData

struct WorkspacesTabView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \WorkspaceDb.sort) private var workspacesDb: [WorkspaceDb] = []
    
    var body: some View {
        List {
            ForEach(workspacesDb) { workspaceDb in
                Text(workspaceDb.name)
                    .contextMenu {
                        Button(
                            action: {
                                modelContext.delete(workspaceDb)
                            },
                            label: {
                                Text("Delete")
                                    .foregroundColor(.red)
                            }
                        )
                    }
                    .padding(.vertical, 4)
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
