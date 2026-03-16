import SwiftUI
import UniformTypeIdentifiers
import HotKey

private let fontSize = 13.0

struct WorkspaceBindView: View {
    
    private let key: Key
    private let workspaceDb: WorkspaceDb?

    @State private var appsUi: [AppUi]
    @State private var formUi: FormUi
    
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
                    ProjectPickerView(
                        path: formUi.substring,
                        pickerButtonText: "Select Xcode Project File or Folder",
                        fileTypes: [.data, .directory],
                        onPathChanged: { path in
                            formUi.substring = path
                        },
                    )
                } else if formUi.bundle == BundleIds.IntelliJ {
                    ProjectPickerView(
                        path: formUi.substring,
                        pickerButtonText: "Select IDEA Project Folder",
                        fileTypes: [.directory],
                        onPathChanged: { path in
                            formUi.substring = path
                        },
                    )
                } else {
                    TextField("Window title (optional)", text: $formUi.substring)
                        .autocorrectionDisabled()
                        .frame(width: 200)
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
    }
}

private let userRelativePathRegex = /^\/Users\/(.*?)\/\b/

private struct ProjectPickerView: View {
    
    let path: String
    let pickerButtonText: String
    let fileTypes: [UTType]
    let onPathChanged: (String) -> Void
    
    ///
    
    @State private var isFilePickerPresented = false
    
    private var validatedPath: String {
        return path.replacing(userRelativePathRegex, with: "~/")
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
