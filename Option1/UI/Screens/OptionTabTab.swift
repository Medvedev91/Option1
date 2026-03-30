import SwiftUI

struct OptionTabTab: View {
    
    @State private var isOptionTabEnabled: Bool = OptionTabManager.instance.isEnabled
    
    var body: some View {
        VStack {
            
            HStack {
                
                Toggle(isOn: $isOptionTabEnabled) {
                    Text("Enable Option-Tab")
                }
                .onChange(of: isOptionTabEnabled) { _, newValue in
                    OptionTabManager.instance.setIsEnabled(newValue)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            List {
                Text("Efeklj")
                Text("Iskf;aja")
            }
        }
        .navigationTitle("Option-Tab")
    }
}
