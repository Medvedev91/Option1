import SwiftUI
import Cocoa

struct WorkspaceScreen: View {
    
    let workspaceDb: WorkspaceDb?
    
    ///
    
    @State private var activeAxuiElements: [AXUIElement] = []
    
    // Fix WTF bug - name is empty on second form open.
    @State private var formId = UUID()
    @State private var formPresented = false
    @State private var formName = ""
    
    var body: some View {
        ScrollView {
            
            ForEach(HotKeysUtils.keys, id: \.self) { key in
                WorkspaceBindView(
                    key: key,
                    workspaceDb: workspaceDb,
                    onSelected: { bundle in
                        guard let runningApplication = NSWorkspace.shared.runningApplications.first(where: {
                            $0.bundleIdentifier?.lowercased() == bundle.lowercased()
                        }) else { return }
                        let pid = runningApplication.processIdentifier
                        let axuiElement = AXUIElementCreateApplication(pid)
                        do {
                            let windows = try axuiElement.allWindows(pid)
                            self.activeAxuiElements = windows
                        } catch {
                            reportApi("WorkspaceScreen onSelected() error: \(error)")
                            return
                        }
                    },
                )
                .padding(.top, key == .one ? 8 : 0)
            }
            
            Divider()
                .padding()
            
            VStack(spacing: 8) {
                ForEach(activeAxuiElements, id: \.self) { axuiElement in
                    ActiveAppView(axuiElement: axuiElement)
                }
            }
        }
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

private struct ActiveAppView: View {
    
    let axuiElement: AXUIElement
    
    ///
    
    private var title: String {
        do {
            return try axuiElement.title() ?? "--"
        } catch {
            reportApi("WorkspaceScreen ActiveAppView title error: \(error)")
            return "--"
        }
    }
    
    var body: some View {
        Text("\(title) #\(axuiElement.id() ?? 0)")
            .textAlign(.leading)
            .padding(.horizontal)
    }
}
