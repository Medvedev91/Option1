import SwiftUI

struct MainTabView: View {
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                Text("Bind Window - Option + Shift + 1 .. 9")
                    .textAlign(.leading)
                    .padding(.top, 4)
                
                Text("Focus Window - Option + 1 .. 9")
                    .textAlign(.leading)
                    .padding(.top, 4)
                
                Divider()
                    .padding(.vertical)
                
                SparkleButtonView()
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Option 1")
    }
}
