import SwiftUI

struct WorkspaceScreen: View {
    
    let workspaceDb: WorkspaceDb?
    
    var body: some View {
        List {
            ForEach(HotKeysUtils.keys, id: \.self) { key in
                HStack {
                    Image(systemName: "option")
                        .font(.system(size: 12, weight: .bold))
                    Text(key.description)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .navigationTitle(workspaceDb?.name ?? "Shared")
    }
}
