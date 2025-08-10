import AppKit
import SwiftUI
import SwiftData
import HotKey

var globalBinds: [PersistentBind] = []

private let keys: [Key] = [.one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .zero]

struct SettingsTabView: View {
    
    @State private var axuiElements: [AXUIElement] = []
    @State private var focusedWindow: AXUIElement? = nil
    @State private var focusedApplicationBundle: String? = nil
    
    @State private var localBinds: [PersistentBind] = globalBinds
    
    @Query private var workspacesDb: [WorkspaceDb] = []
    
    @State private var formKey: Key = .one
    @State private var formWorkspaceDb: WorkspaceDb? = nil
    @State private var formBundle: String = ""
    @State private var formSubstring: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                
                Button("Debug") {
                    Task {
                        try await Task.sleep(nanoseconds: 2_000_000_000)
                        let axuiElements = try! WindowsManager.getWindowsForActiveApplicationOrNil() ?? []
                        self.axuiElements = axuiElements
                        self.focusedWindow = try! WindowsManager.getFocusedWindowOrNil()
                        self.focusedApplicationBundle = WindowsManager.getActiveApplicationOrNil()?.bundleIdentifier
                    }
                }
                
                if let focusedApplicationBundle = focusedApplicationBundle {
                    Text(focusedApplicationBundle).onTapGesture {
                        formBundle = focusedApplicationBundle
                    }
                }
                
                if let focusedWindow = focusedWindow {
                    Button("Focused \(try! focusedWindow.title() ?? "-") \(focusedWindow.id() ?? 0)") {
                        try! WindowsManager.focusWindow(axuiElement: focusedWindow)
                    }
                }
                
                ForEach(axuiElements, id: \.self) { axuiElement in
                    Button("Run \(try! axuiElement.title() ?? "-") \(axuiElement.id() ?? 0)") {
                        try! WindowsManager.focusWindow(axuiElement: axuiElement)
                    }
                }
                
                SparkleButtonView()
                    .padding(.top, 10)
                
                Divider()
                    .padding(.vertical)
                
                ForEach(localBinds, id: \.self) { bind in
                    Text("\(bind.key.description) - \(bind.workspaceDb.name) - \(bind.bundle) - \(bind.substring)")
                        .onTapGesture {
                            localBinds.remove(at: localBinds.firstIndex(of: bind)!)
                        }
                }
                
                HStack {
                    Picker("", selection: $formKey) {
                        ForEach(keys, id: \.self) { key in
                            Text(key.description).tag(key)
                        }
                    }
                    .frame(width: 60)
                    Picker("", selection: $formWorkspaceDb) {
                        if formWorkspaceDb == nil {
                            Text("").tag(nil as WorkspaceDb?)
                        }
                        ForEach(workspacesDb) { workspaceDb in
                            Text(workspaceDb.name).tag(workspaceDb as WorkspaceDb?)
                        }
                    }
                    .frame(width: 150)
                    TextField("Bundle Identifier", text: $formBundle)
                        .autocorrectionDisabled()
                    TextField("Title Substring", text: $formSubstring)
                        .autocorrectionDisabled()
                    Button("Add") {
                        if let formWorkspaceDb = formWorkspaceDb {
                            localBinds.append(
                                PersistentBind(
                                    key: formKey,
                                    workspaceDb: formWorkspaceDb,
                                    bundle: formBundle.lowercased(),
                                    substring: formSubstring.lowercased(),
                                )
                            )
                        }
                    }
                }
                
                Spacer()
                    .frame(height: 1)
                    .fillMaxWidth()
            }
            .padding()
        }
        .navigationTitle("Settings")
        .onChange(of: localBinds) { _, newLocalBinds in
            globalBinds = newLocalBinds
        }
    }
}

struct PersistentBind: Hashable {
    let key: Key
    let workspaceDb: WorkspaceDb
    let bundle: String
    let substring: String
}
