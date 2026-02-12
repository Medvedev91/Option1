import SwiftUI

struct SettingsTab: View {
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    SparkleButtonView()
                    Text("v\(SystemInfo.getAppVersionOrNil().map { "\($0)" } ?? "unknown").\(SystemInfo.getBuildOrNil().map { "\($0)" } ?? "unknown")")
                    Spacer()
                }
            }
            .padding()
        }
        .navigationTitle("Settings")
    }
}
