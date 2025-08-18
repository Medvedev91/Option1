import SwiftUI

struct WorkspaceScreen: View {
    
    let workspaceDb: WorkspaceDb?
    
    ///
    
    // Fix WTF bug - name is empty on second form open.
    @State private var formId = UUID()
    @State private var formPresented = false
    @State private var formName = ""
    
    var body: some View {
        List {
            ForEach(HotKeysUtils.keys, id: \.self) { key in
                HStack {
                    Image(systemName: "option")
                        .font(.system(size: 12, weight: .bold))
                    Text(key.description)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .alert("", isPresented: $formPresented) {
            TextField("Workspace", text: $formName)
            Button("Cancel") {
            }
            .keyboardShortcut(.cancelAction)
            Button("Save") {
                workspaceDb?.updateName(formName)
            }
            .disabled(formName.isEmpty)
            .keyboardShortcut(.defaultAction)
        }
        .id(formId)
        .navigationTitle(workspaceDb?.name ?? "Shared")
        .toolbar {
            if let workspaceDb = workspaceDb {
                ToolbarItem(placement: .primaryAction) {
                    RenameButton()
                        .renameAction {
                            showForm(workspaceDb: workspaceDb)
                        }
                }
            }
        }
    }
    
    private func showForm(workspaceDb: WorkspaceDb) {
        formId = UUID()
        formName = workspaceDb.name
        formPresented = true
    }
}
