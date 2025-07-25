import SwiftUI
import Cocoa

struct ContentView: View {
    
    @State private var axuiElements: [AXUIElement] = []
    @State private var focusedWindow: AXUIElement? = nil
    
    var body: some View {
        VStack {
            
            Button("Get") {
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
        }
        .padding()
    }
}
