import SwiftUI
import SwiftData

struct WorkspacesTabView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \WorkspaceDb.sort) private var workspacesDb: [WorkspaceDb] = []
    
    var body: some View {
        List {
            Section {
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
                }
            }
        }
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
}
