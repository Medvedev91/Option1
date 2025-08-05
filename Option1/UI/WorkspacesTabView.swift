import SwiftUI

struct WorkspacesTabView: View {
    
    var body: some View {
        ScrollView {
            VStack {
            }
        }
        .navigationTitle("Workspaces")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Workspace") {
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
