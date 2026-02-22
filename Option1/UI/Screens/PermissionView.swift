import SwiftUI

struct PermissionView: View {
    
    var body: some View {
        VStack {
            
            Label(
                " Please allow Option1 handling hotkeys",
                systemImage: "lightbulb"
            )
            .font(.system(size: 28, weight: .medium))
            
            Button(
                action: {
                    _ = isAccessibilityGranted(showDialog: true)
                },
                label: {
                    Label(
                        "Open Privacy & Security -> Accessibility Settings",
                        systemImage: "arrow.right.circle.fill"
                    )
                    .font(.system(size: AppText.FONT_SIZE, weight: .medium))
                }
            )
            .padding(.top, 20)
            
            Image("permissions")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 800)
        }
    }
}
