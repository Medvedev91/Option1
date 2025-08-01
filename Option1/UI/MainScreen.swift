import SwiftUI
import Cocoa

struct MainScreen: View {
    
    @State private var axuiElements: [AXUIElement] = []
    @State private var focusedWindow: AXUIElement? = nil
    
    private let timer1s = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var isPermissionGranted = isAccessibilityGranted(showDialog: false)
    
    var body: some View {
        VStack {
            
            if !isPermissionGranted {
                PermissionView()
            } else {
                
                Button("Debug App in 3 Seconds") {
                    Task {
                        try await Task.sleep(nanoseconds: 3_000_000_000)
                        let axuiElements = try! WindowsManager.getWindowsForActiveApplicationOrNil() ?? []
                        self.axuiElements = axuiElements
                        self.focusedWindow = try! WindowsManager.getFocusedWindowOrNil()
                    }
                }
                
                if let focusedWindow = focusedWindow {
                    Button("Focused \(try! focusedWindow.title()) \(focusedWindow.id())") {
                        try! WindowsManager.focusWindow(axuiElement: focusedWindow)
                    }
                }
                
                ForEach(axuiElements, id: \.self) { axuiElement in
                    Button("Run \(try! axuiElement.title()) \(axuiElement.id())") {
                        try! WindowsManager.focusWindow(axuiElement: axuiElement)
                    }
                }
                
                SparkleButtonView()
            }
        }
        .padding()
        .onReceive(timer1s) { _ in
            isPermissionGranted = isAccessibilityGranted(showDialog: false)
        }
    }
}
