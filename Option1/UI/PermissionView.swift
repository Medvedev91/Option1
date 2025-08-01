import SwiftUI

struct PermissionView: View {
    
    var body: some View {
        VStack {
            
            Text("Permissions are required to handle hotkeys.")
                .foregroundColor(.red)
                .fontWeight(.medium)

            Button("Grant Permissions") {
                _ = isAccessibilityGranted(showDialog: true)
            }
            .padding(.top, 8)
        }
    }
}
