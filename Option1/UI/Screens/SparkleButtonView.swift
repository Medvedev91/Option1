//
// Source https://sparkle-project.org/documentation/programmatic-setup/
//

import SwiftUI
import Sparkle

struct SparkleButtonView: View {
    
    @ObservedObject private var sparkleVm = SparkleVm()
    
    var body: some View {
        Button("Check for Updates", action: sparkleController.updater.checkForUpdates)
            .disabled(!sparkleVm.canCheckForUpdates)
    }
}

///

private class SparkleVm: ObservableObject {
    
    @Published var canCheckForUpdates = false
    
    init() {
        sparkleController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}
