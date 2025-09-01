import SwiftUI
import HotKey

struct WorkspaceBindView: View {
    
    private let key: Key
    private let workspaceDb: WorkspaceDb?
    private let onSelected: (String /* Bundle */) -> Void
    
    @State private var appsUi: [AppUi]
    @State private var formUi: FormUi
    
    init(
        key: Key,
        workspaceDb: WorkspaceDb?,
        onSelected: @escaping (String) -> Void,
    ) {
        self.key = key
        self.workspaceDb = workspaceDb
        self.appsUi = buildAppsUi()
        let bindDb: BindDb? = selectBindDbOrNil(workspaceDb: workspaceDb, key: key)
        self.formUi = FormUi(bundle: bindDb?.bundle, substring: bindDb?.substring ?? "")
        self.onSelected = onSelected
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
                TextField("Title Substring (optional)", text: $formUi.substring)
                    .autocorrectionDisabled()
                    .frame(width: 180)
            }
            
            Spacer()
        }
        .padding(.leading, 12)
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
        .onChange(of: formUi) { _, newFormUi in
            if let bundle = newFormUi.bundle {
                onSelected(bundle)
            }
        }
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

private func buildAppsUi() -> [AppUi] {
    var localAppsUi: [AppUi] = NSWorkspace.shared.runningApplications
        .filter { $0.activationPolicy == .regular }
        .compactMap { app in
            guard let title = app.localizedName, let bundle = app.bundleIdentifier else { return nil }
            return AppUi(title: title, bundle: bundle)
        }
    // todo if bind not in list
    // todo update list on app activate
    return localAppsUi
}
