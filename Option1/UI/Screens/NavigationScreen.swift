import SwiftUI
import SwiftData

struct NavigationScreen: View {
    
    @State private var tab: Tab = .main
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var isDonationsAlertPresented = false
    
    @State private var isNewWorkspacePresented = false
    @State private var newWorkspaceName: String = ""
    
    @StateObject private var menuBarManager = MenuBarManager.instance
    @Query(sort: \WorkspaceDb.sort) private var workspacesDb: [WorkspaceDb]
    
    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            sidebar: {
                VStack(spacing: 0) {
                    
                    List(selection: $tab) {
                        
                        Label("How to Use", systemImage: "info.circle")
                            .tag(Tab.main)
                        
                        if !isScreenshotsMode {
                            
                            Label("Option-Tab", systemImage: "macwindow.stack")
                                .tag(Tab.optionTab)
                            
                            Label("Settings", systemImage: "gearshape")
                                .tag(Tab.settings)
                            
                            Label("Donations", systemImage: "heart")
                                .tag(Tab.donations)
                        }
                        
                        Section("Workspaces") {
                            
                            Label("Shared", systemImage: menuBarManager.workspaceDb == nil ? "inset.filled.circle" : "circle")
                                .tag(Tab.workspace(workspaceDb: nil))
                            
                            ForEach(workspacesDb) { workspaceDb in
                                WorkspaceItemView(
                                    workspaceDb: workspaceDb,
                                    onDelete: {
                                        tab = .workspace(workspaceDb: nil)
                                    },
                                )
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
                                newWorkspaceName = ""
                                isNewWorkspacePresented = true
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
                Group {
                    switch tab {
                    case .main:
                        MainTab()
                    case .settings:
                        SettingsTab(
                            onDonationsClick: {
                                tab = .donations
                            },
                        )
                    case .optionTab:
                        OptionTabTab()
                    case .donations:
                        DonationsTab()
                    case .workspace(let workspaceDb):
                        WorkspaceScreen(workspaceDb: workspaceDb)
                            .id("WorkspaceScreen \(workspaceDb?.id.uuidString ?? "")")
                    }
                }
                .toolbar {
                    if !isScreenshotsMode {
                        ToolbarItemGroup(placement: .primaryAction) {
                            if #available(macOS 26.0, *), case .workspace = tab {
                                Button("How to Use") {
                                    tab = .main
                                }
                            } else {
                            }
                            Button("Hide") {
                                closeAppWindow()
                            }
                        }
                    }
                }
            }
        )
        .onChange(of: tab, initial: true) { _, newTab in
            if case let .workspace(workspaceDb) = newTab {
                menuBarManager.setWorkspaceDb(workspaceDb)
            }
        }
        .onReceive(DonationsAlertUtils.instance.$needToShow) { needToShow in
            if needToShow {
                DonationsAlertUtils.instance.needToShow = false
                tab = .donations
                isDonationsAlertPresented = true
            }
        }
        .confirmationDialog(
            "Option1 is 100% free. I only ask for donations.",
            isPresented: $isDonationsAlertPresented,
        ) {
            Button("Donate Any Amount") {
                KvDb.upsertDonationsLastAlertTime()
            }
            .keyboardShortcut(.defaultAction)
            
            Button("Another Time", role: .cancel) {
                KvDb.upsertDonationsLastAlertTime()
            }
        } message: {
            Text("Please donate any amount to hide donation notifications.")
        }
        .alert("New Workspace", isPresented: $isNewWorkspacePresented) {
            TextField("Name", text: $newWorkspaceName)
            Button("Cancel") {
            }
            .keyboardShortcut(.cancelAction)
            Button("Create") {
                let workspaceDb = WorkspaceDb.insert(name: newWorkspaceName)
                tab = .workspace(workspaceDb: workspaceDb)
            }
            .disabled(newWorkspaceName.isEmpty)
            .keyboardShortcut(.defaultAction)
        }
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
    case optionTab
    case settings
    case donations
    case workspace(workspaceDb: WorkspaceDb?)
}

private struct WorkspaceItemView: View {
    
    let workspaceDb: WorkspaceDb
    let onDelete: () -> Void
    
    ///
    
    @StateObject private var menuBarManager = MenuBarManager.instance
    
    @State private var isDeleteConfirmationPresented = false
    
    @State private var isRenamePresented = false
    @State private var editName: String = ""
    
    // Fix WTF bug - name is empty on second form open.
    @State private var uuid = UUID()

    var body: some View {
        
        Label(workspaceDb.name, systemImage: menuBarManager.workspaceDb?.id == workspaceDb.id ? "inset.filled.circle" : "circle")
            .id(uuid)
            .tag(Tab.workspace(workspaceDb: workspaceDb))
            .contextMenu {
                Button(
                    action: {
                        isRenamePresented = true
                    },
                    label: {
                        Text("Rename")
                    },
                )
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
                    onDelete()
                }
                .keyboardShortcut(.defaultAction)
                
                Button("No", role: .cancel) {}
            }
            .alert("", isPresented: $isRenamePresented) {
                TextField("Name", text: $editName)
                Button("Cancel") {
                }
                .keyboardShortcut(.cancelAction)
                Button("Save") {
                    workspaceDb.updateName(editName)
                    uuid = UUID()
                }
                .disabled(editName.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .onAppear {
                editName = workspaceDb.name
            }
    }
}
