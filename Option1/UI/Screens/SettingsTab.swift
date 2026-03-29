import SwiftUI

struct SettingsTab: View {
    
    let onDonationsClick: () -> Void
    
    ///
    
    @State private var isBackupAlertPresented = false
    @State private var backupAlertText = ""
    
    @State private var isRestorePickerPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                AppText("Website [option1.io](https://option1.io)")
                
                AppText("Any Questions [ivan@option1.io](mailto:ivan@option1.io)")
                
                AppText("Open Source [https://github.com/Medvedev91/Option1](https://github.com/Medvedev91/Option1)")
                
                HStack {
                    Text("Donations ")
                        .font(.system(size: AppText.FONT_SIZE))
                    +
                    Text(verbatim: "https://buymeacoffee.com/medvedev91")
                        .font(.system(size: AppText.FONT_SIZE))
                        .foregroundColor(Color(.linkColor))
                }
                .onTapGesture {
                    onDonationsClick()
                }
                
                HStack {
                    Button(
                        action: {
                            Task { @MainActor in
                                do {
                                    try saveBackup(Backup.prepareBackup())
                                    showBackupAlert("Backup saved!")
                                } catch AppError.simple(let message) {
                                    showBackupAlert(message)
                                }
                            }
                        },
                        label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                    .offset(y: -1)
                                    .fontWeight(.semibold)
                                Text("Backup")
                            }
                        },
                    )
                    Button(
                        action: {
                            isRestorePickerPresented = true
                        },
                        label: {
                            HStack {
                                Image(systemName: "arrow.up.right")
                                    .fontWeight(.semibold)
                                Text("Restore")
                            }
                        }
                    )
                    .fileImporter(
                        isPresented: $isRestorePickerPresented,
                        allowedContentTypes: [.data],
                        onCompletion: { result in
                            switch result {
                            case .success(let url):
                                do {
                                    let jString: String = try String(contentsOfFile: url.path, encoding: .utf8)
                                    try Backup.restore(jString: jString)
                                    showBackupAlert("Restored")
                                } catch AppError.simple(let message) {
                                    showBackupAlert(message)
                                } catch {
                                    showBackupAlert("Error")
                                }
                            case .failure:
                                showBackupAlert("Error!")
                                break
                            }
                        }
                    )
                }

                HStack {
                    SparkleButtonView()
                    Text("v\(SystemInfo.getAppVersionOrNil().map { "\($0)" } ?? "unknown").\(SystemInfo.getBuildOrNil().map { "\($0)" } ?? "unknown")")
                    Spacer()
                }
            }
            .padding()
        }
        .navigationTitle("Settings")
        .alert(
            "",
            isPresented: $isBackupAlertPresented,
            actions: {},
            message: { Text(backupAlertText) },
        )
    }
    
    private func showBackupAlert(_ text: String) {
        backupAlertText = text
        isBackupAlertPresented = true
    }
}

private func saveBackup(_ fileContent: String) throws(AppError) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    let savePanel = NSSavePanel()
    savePanel.allowedContentTypes = [.json]
    savePanel.isExtensionHidden = false
    savePanel.title = "Backup"
    savePanel.nameFieldLabel = "File Name:"
    savePanel.nameFieldStringValue = "Option1-Backup-\(dateFormatter.string(from: Date.now))"
    let response = savePanel.runModal()
    guard response == .OK, let url: URL = savePanel.url else {
        throw AppError.simple("Error! Backup canceled!")
    }
    
    do {
        try fileContent.write(to: url, atomically: true, encoding: String.Encoding.utf8)
    } catch {
        throw AppError.simple("Error! Backup failed!")
    }
}
