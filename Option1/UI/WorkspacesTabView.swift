import SwiftUI
import SwiftData

struct WorkspacesTabView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query private var workspacesDb: [WorkspaceDb] = []
    
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
                }
                .buttonStyle(.link)
            }
        }
    }
}
