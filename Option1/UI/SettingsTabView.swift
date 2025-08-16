import AppKit
import SwiftUI
import SwiftData
import HotKey
import Cocoa

private let keys: [Key] = [.one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .zero]

struct SettingsTabView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var axuiElements: [AXUIElement] = []
    @State private var focusedWindow: AXUIElement? = nil
    
    @Query private var bindsDb: [BindDb] = []
    @State private var bindsUi: [BindUi] = []
    
    private let nsApps: [NSRunningApplication] = NSWorkspace.shared.runningApplications.filter {
        $0.activationPolicy == .regular
    }
    
    @Query private var workspacesDb: [WorkspaceDb] = []
    
    @State private var formKey: Key = .one
    @State private var formWorkspaceDb: WorkspaceDb? = nil
    @State private var formNsApp: NSRunningApplication?
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
                
                ForEach(bindsUi, id: \.self) { bindUi in
                    let bindDb = bindUi.bindDb
                    Text("\(bindDb.key) - \(bindUi.workspaceDb?.name ?? "Shared") - \(bindDb.bundle) - \(bindDb.substring)")
                        .onTapGesture {
                            bindDb.delete()
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
                        Text("Shared").tag(nil as WorkspaceDb?)
                        ForEach(workspacesDb) { workspaceDb in
                            Text(workspaceDb.name).tag(workspaceDb as WorkspaceDb?)
                        }
                    }
                    .frame(width: 150)
                    
                    Picker("", selection: $formNsApp) {
                        if formNsApp == nil {
                            Text("").tag(nil as NSRunningApplication?)
                        }
                        ForEach(nsApps, id: \.self) { nsApp in
                            Text(nsApp.bundleIdentifier ?? "-").tag(nsApp as NSRunningApplication?)
                        }
                    }
                    
                    TextField("Title Substring", text: $formSubstring)
                        .autocorrectionDisabled()
                    Button("Add") {
                        if let formNsApp = formNsApp {
                            BindDb.insert(
                                key: formKey.description,
                                workspaceDb: formWorkspaceDb,
                                bundle: formNsApp.bundleIdentifier!,
                                substring: formSubstring,
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
        .onChange(of: formNsApp) { _, newValue in
            if let newValue = newValue {
                let pid = newValue.processIdentifier
                let axuiElement = AXUIElementCreateApplication(pid)
                let windows = try! axuiElement.allWindows(pid)
                self.axuiElements = windows
            }
        }
        .onChange(of: bindsDb, initial: true) { _, newBindsDb in
            let workspacesDb = WorkspaceDb.selectAll()
            bindsUi = newBindsDb.map { bindDb in
                BindUi(
                    bindDb: bindDb,
                    workspaceDb: workspacesDb.first { $0.id == bindDb.workspaceId },
                )
            }
        }
    }
}

private struct BindUi: Hashable {
    let bindDb: BindDb
    let workspaceDb: WorkspaceDb?
}
