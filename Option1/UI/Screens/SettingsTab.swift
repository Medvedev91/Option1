import SwiftUI

struct SettingsTab: View {
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                AppText("Website [option1.io](https://option1.io)")
                
                AppText("Any Questions [ivan@option1.io](mailto:ivan@option1.io)")
                
                AppText("Open Source [https://github.com/Medvedev91/Option1](https://github.com/Medvedev91/Option1)")
                
                HStack {
                    SparkleButtonView()
                    Text("v\(SystemInfo.getAppVersionOrNil().map { "\($0)" } ?? "unknown").\(SystemInfo.getBuildOrNil().map { "\($0)" } ?? "unknown")")
                    Spacer()
                }
                .padding(.top, 2)
            }
            .padding()
        }
        .navigationTitle("Settings")
    }
}
