import SwiftUI
import UniformTypeIdentifiers
import HotKey

private let fontSize = 13.0

struct WorkspaceBindView: View {
    
    private let key: Key
    private let workspaceDb: WorkspaceDb?

    @State private var appsUi: [AppUi]
    @State private var formUi: FormUi
    
    @State private var isTitleInfoPresented = false
    
    private var selectedAppName: String? {
        appsUi.first(where: { $0.bundle == formUi.bundle })?.title
    }
    
    @State private var isAnyFilePickerPresented = false
    @State private var isAnyFilePickerInfoPresented = false
    
    // Т.к. одновременно данное View отображается 10 раз а в формировании
    // списка много внутренней логики нужно давать хотябы 2 секунды.
    private let updateAppsUiTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    private let sharedOverride: String?
    
    init(
        key: Key,
        workspaceDb: WorkspaceDb?,
    ) {
        self.key = key
        self.workspaceDb = workspaceDb
        self.appsUi = buildAppsUi()
        let bindDb: BindDb? = selectBindDbOrNil(workspaceDb: workspaceDb, key: key)
        self.formUi = FormUi(bundle: bindDb?.bundle, substring: bindDb?.substring ?? "")
        self.sharedOverride = findSharedOverride(key: key, workspaceDb: workspaceDb)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            
            Image(systemName: "option")
                .font(.system(size: 12, weight: .bold))
                .padding(.trailing, 6)
            
            Text(key.description)
                .font(.system(size: fontSize, weight: .semibold))
                .frame(width: 12)
                .padding(.vertical, 8)
            
            Picker("", selection: $formUi.bundle) {
                Text("").tag(nil as String?)
                Section("Open Apps") {
                    ForEach(appsUi, id: \.self) { appUi in
                        Text(appUi.title).tag(appUi.bundle)
                    }
                }
            }
            .padding(.leading, 2)
            .padding(.trailing, 12)
            
            if formUi.bundle != nil {
                
                if formUi.bundle == BundleIds.Xcode {
                    FileTypeView(
                        path: formUi.substring,
                        pickerButtonText: "Select Xcode Project File or Folder",
                        fileTypes: [.data, .directory],
                        onPathChanged: { path in
                            formUi.substring = path
                        },
                    )
                } else if formUi.bundle == BundleIds.IntelliJ {
                    FileTypeView(
                        path: formUi.substring,
                        pickerButtonText: "Select IDEA Project Folder",
                        fileTypes: [.directory],
                        onPathChanged: { path in
                            formUi.substring = path
                        },
                    )
                } else if formUi.bundle == BundleIds.MicrosoftWord {
                    FileTypeView(
                        path: formUi.substring,
                        pickerButtonText: "Select Word Document",
                        fileTypes: [.data],
                        onPathChanged: { path in
                            formUi.substring = path
                        },
                    )
                } else if isFileExists(formUi.substring) {
                    FileTypeView(
                        path: formUi.substring,
                        pickerButtonText: "---", // Impossible to show because of .isFileExists()
                        fileTypes: [.data, .directory],
                        onPathChanged: { path in
                            formUi.substring = path
                        },
                    )
                } else {
                    
                    TextField("Window title (optional)", text: $formUi.substring)
                        .autocorrectionDisabled()
                        .frame(width: 180)
                    
                    if !isScreenshotsMode {
                        Button(
                            action: {
                                isAnyFilePickerInfoPresented = true
                            },
                            label: {
                                Image(systemName: "folder")
                                    .font(.system(size: fontSize, weight: .regular))
                                    .foregroundColor(.secondary)
                            },
                        )
                        .buttonStyle(.borderless)
                        .padding(.leading, 12)
                        .confirmationDialog(
                            "",
                            isPresented: $isAnyFilePickerInfoPresented,
                        ) {
                            Button("Select File or Folder") {
                                isAnyFilePickerPresented = true
                            }
                            .keyboardShortcut(.defaultAction)
                            
                            Button("Cancel", role: .cancel) {
                            }
                        } message: {
                            Text("If \(selectedAppName ?? "the app") supports opening files or folders, select the one you want to open.\n\nIf the file doesn't open properly, please contact me. I'll research this app.")
                        }
                        .fileImporter(
                            isPresented: $isAnyFilePickerPresented,
                            allowedContentTypes: [.data, .directory],
                            onCompletion: { result in
                                switch result {
                                case .success(let url):
                                    formUi.substring = url.relativePath
                                case .failure:
                                    break
                                }
                            }
                        )
                        
                        Button(
                            action: {
                                isTitleInfoPresented = true
                            },
                            label: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: fontSize, weight: .regular))
                                    .foregroundColor(.secondary)
                            },
                        )
                        .buttonStyle(.borderless)
                        .padding(.leading, 8)
                    }
                }
            } else if let sharedOverride = sharedOverride {
                HStack(spacing: 0) {
                    Text(sharedOverride)
                        .foregroundColor(.secondary)
                        .font(.system(size: fontSize, weight: .semibold))
                        .padding(.vertical, 8)
                    Text(" from shared")
                        .foregroundColor(.secondary)
                        .font(.system(size: fontSize))
                        .padding(.vertical, 8)
                }
            }
            
            Spacer()
        }
        .padding(.leading, 12)
        .onReceive(updateAppsUiTimer) { _ in
            appsUi = buildAppsUi()
        }
        .onChange(of: formUi) { _, newFormUi in
            let bundle: String? = newFormUi.bundle
            let bindDb: BindDb? = selectBindDbOrNil(workspaceDb: workspaceDb, key: key)
            if let bundle = bundle {
                if let bindDb = bindDb {
                    bindDb.updateBundleAndSubstring(
                        bundle: bundle,
                        substring: newFormUi.substring,
                    )
                } else {
                    BindDb.insert(
                        key: key.description,
                        workspaceDb: workspaceDb,
                        bundle: bundle,
                        substring: newFormUi.substring,
                    )
                }
            } else {
                if let bindDb = bindDb {
                    bindDb.delete()
                }
            }
        }
        .alert(
            "",
            isPresented: $isTitleInfoPresented,
            actions: {},
            message: { Text("If you have multiple \(selectedAppName ?? "app") windows open, enter the window title for window you want to open.\n\nYou can enter part of title as well.") }
        )
    }
}

private let userRelativePathRegex = /^\/Users\/(.*?)\/\b/

private struct FileTypeView: View {
    
    let path: String
    let pickerButtonText: String
    let fileTypes: [UTType]
    let onPathChanged: (String) -> Void
    
    ///
    
    @State private var isFilePickerPresented = false
    
    private var validatedPath: String {
        path.replacing(userRelativePathRegex, with: "~/")
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if path.isEmpty {
                Button(
                    action: {
                        isFilePickerPresented = true
                    },
                    label: {
                        Label(pickerButtonText, systemImage: "folder")
                    },
                )
            } else {
                Text(validatedPath)
                    .padding(.vertical, 8)
                    .foregroundColor(.blue)
                    .font(.system(size: fontSize, weight: .regular))
                    .onTapGesture {
                        isFilePickerPresented = true
                    }
                
                Button(
                    action: {
                        onPathChanged("")
                    },
                    label: {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: fontSize, weight: .regular))
                    },
                )
                .buttonStyle(.borderless)
            }
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: fileTypes,
            onCompletion: { result in
                switch result {
                case .success(let url):
                    onPathChanged(url.relativePath)
                case .failure:
                    break
                }
            }
        )
        .fileDialogDefaultDirectory(path.isEmpty ? nil : URL(filePath: path))
    }
}

///

private struct AppUi: Hashable {
    var title: String
    var bundle: String
}

private struct FormUi: Hashable {
    var bundle: String?
    var substring: String
}

@MainActor
private func selectBindDbOrNil(workspaceDb: WorkspaceDb?, key: Key) -> BindDb? {
    BindDb.selectAll().first {
        $0.key == key.description && $0.workspaceId == workspaceDb?.id
    }
}

@MainActor
private func buildAppsUi() -> [AppUi] {
    var localAppsUi: [AppUi] = AppDb.selectAll().compactMap { appDb in
        AppUi(title: appDb.name, bundle: appDb.bundle)
    }
    let usedBundles: [String] = localAppsUi.map(\.bundle)
    BindDb.selectAll()
        .filter { !usedBundles.contains($0.bundle) }
        .map(\.bundle)
        .unique()
        .forEach { bundle in
            localAppsUi.append(AppUi(title: bundle, bundle: bundle))
        }
    return localAppsUi.sorted { $0.title.lowercased() < $1.title.lowercased() }
}

@MainActor
private func findSharedOverride(
    key: Key,
    workspaceDb: WorkspaceDb?,
) -> String? {
    if workspaceDb == nil {
        return nil
    }
    let sharedBindDb: BindDb? = BindDb.selectAll()
        .first { $0.workspaceId == nil && $0.key == key.description }
    let appDb: AppDb? = AppDb.selectAll()
        .first { $0.bundle == sharedBindDb?.bundle }
    return appDb?.name ?? sharedBindDb?.bundle
}
