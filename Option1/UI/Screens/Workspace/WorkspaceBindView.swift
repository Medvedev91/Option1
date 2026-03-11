import SwiftUI
import HotKey

struct WorkspaceBindView: View {
    
    private let key: Key
    private let workspaceDb: WorkspaceDb?
    
    @State private var isFilePickerPresented = false

    @State private var appsUi: [AppUi]
    @State private var formUi: FormUi
    
    // Т.к. одновременно данное View отображается 10 раз а в формировании
    // списка много внутренней логики нужно давать хотябы 2 секунды.
    private let updateAppsUiTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    private var placeholder: String {
        if formUi.bundle == BundleIds.Xcode { return "Xcode project path or title" }
        if formUi.bundle == BundleIds.IntelliJ { return "IDEA project path or title" }
        return "Title substring (optional)"
    }
    
    private var showFilePickerButton: Bool {
        formUi.bundle == BundleIds.Xcode ||
        formUi.bundle == BundleIds.IntelliJ
    }
    
    private var filePickerButtonText: String {
        if formUi.bundle == BundleIds.Xcode { return isFileExists(formUi.substring) ? "Selected" : "Select Project" }
        if formUi.bundle == BundleIds.IntelliJ { return isFileExists(formUi.substring) ? "Selected" : "Select Project" }
        return "Select"
    }

    private var filePickerButtonIcon: String {
        if formUi.bundle == BundleIds.Xcode { return isFileExists(formUi.substring) ? "checkmark" : "magnifyingglass" }
        if formUi.bundle == BundleIds.IntelliJ { return isFileExists(formUi.substring) ? "checkmark" : "magnifyingglass" }
        return "Select"
    }

    private var filePickerButtonTint: Color? {
        if formUi.bundle == BundleIds.Xcode { return isFileExists(formUi.substring) ? .green : nil }
        if formUi.bundle == BundleIds.IntelliJ { return isFileExists(formUi.substring) ? .green : nil }
        return nil
    }

    init(
        key: Key,
        workspaceDb: WorkspaceDb?,
    ) {
        self.key = key
        self.workspaceDb = workspaceDb
        self.appsUi = buildAppsUi()
        let bindDb: BindDb? = selectBindDbOrNil(workspaceDb: workspaceDb, key: key)
        self.formUi = FormUi(bundle: bindDb?.bundle, substring: bindDb?.substring ?? "")
    }
    
    var body: some View {
        HStack(spacing: 0) {
            
            Image(systemName: "option")
                .font(.system(size: 12, weight: .bold))
                .padding(.trailing, 6)
            
            Text(key.description)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 12)
                .padding(.vertical, 8)
            
            Picker("", selection: $formUi.bundle) {
                Text("").tag(nil as String?)
                ForEach(appsUi, id: \.self) { appUi in
                    Text(appUi.title).tag(appUi.bundle)
                }
            }
            .frame(width: 180)
            .padding(.trailing, 8)
            
            if formUi.bundle != nil {
                TextField(placeholder, text: $formUi.substring)
                    .autocorrectionDisabled()
                    .frame(width: 200)
                if showFilePickerButton {
                    Button(
                        action: {
                            isFilePickerPresented = true
                        },
                        label: {
                            Label(filePickerButtonText, systemImage: filePickerButtonIcon)
                        },
                    )
                    .padding(.leading)
                    .tint(filePickerButtonTint)
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
        .fileImporter(
            isPresented: $isFilePickerPresented,
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
    }
}

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
    var localAppsUi: [AppUi] = NSWorkspace.shared.runningApplications
        .filter { $0.activationPolicy == .regular }
        .compactMap { app in
            guard let title = app.localizedName, let bundle = app.bundleIdentifier else { return nil }
            return AppUi(title: title, bundle: bundle)
        }
    let usedBundles: [String] = localAppsUi.map(\.bundle)
    BindDb.selectAll()
        .filter { !usedBundles.contains($0.bundle) }
        .map(\.bundle)
        .unique()
        .forEach { bundle in
            localAppsUi.append(AppUi(title: bundle, bundle: bundle))
        }
    // todo update list on app activate
    return localAppsUi
}
