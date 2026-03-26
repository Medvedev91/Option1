import SwiftUI

struct SettingsTab: View {
    
    let onDonationsClick: () -> Void
    
    ///
    
    @State private var isBackupAlertPresented = false
    @State private var backupAlertText = ""
    
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
                    SparkleButtonView()
                    Text("v\(SystemInfo.getAppVersionOrNil().map { "\($0)" } ?? "unknown").\(SystemInfo.getBuildOrNil().map { "\($0)" } ?? "unknown")")
                    Spacer()
                }
                .padding(.top, 2)
                
                HStack {
                    Button("Backup") {
                        backupAlertText = saveBackup(Backup.prepareBackup()) ? "Backup Created" : "Error"
                        isBackupAlertPresented = true
                    }
                    Button("Restore") {
                    }
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
}

private func saveBackup(_ fileContent: String) -> Bool {
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
        return false
    }
    
    do {
        try fileContent.write(to: url, atomically: true, encoding: String.Encoding.utf8)
        return true
    } catch {
        return false
    }
}
