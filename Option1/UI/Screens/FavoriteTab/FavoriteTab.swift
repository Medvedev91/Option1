import SwiftUI
import SwiftData

struct FavoriteTab: View {
    
    @State private var addFormBundle: String? = nil
    @State private var addFormName: String = ""
    @State private var addFormSubstring: String = ""
    
    @Query private var appsDb: [AppDb]
    
    @State private var favoritesUi: [FavoriteUi] = []
    
    private var formAppsUi: [FormAppUi] {
        appsDb
            .sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
            .map { appDb in
                FormAppUi(
                    title: appDb.name,
                    bundle: appDb.bundle,
                )
            }
    }
    
    var body: some View {
        VStack {
            
            HStack {
                
                Picker("", selection: $addFormBundle) {
                    Text("")
                        .tag(nil as String?)
                    Section("Open Apps") {
                        ForEach(formAppsUi, id: \.self) { appUi in
                            Text(appUi.title)
                                .tag(appUi.bundle)
                        }
                    }
                }
                
                TextField("Name", text: $addFormName)
                    .autocorrectionDisabled()
                    .frame(width: 140)
                
                Button("Add to Favorite") {
                    if let addFormBundle = addFormBundle {
                        _ = FavoriteDb.insert(
                            bundle: addFormBundle,
                            name: addFormName,
                            substring: addFormSubstring,
                        )
                        self.addFormBundle = nil
                        self.addFormName = ""
                        self.addFormSubstring = ""
                    }
                    syncFavoritesUi()
                }
                .disabled(addFormBundle == nil)
                
                Spacer()
            }
            .padding(.horizontal, 8)
            
            List {
                ForEach(favoritesUi, id: \.favoriteDb.id) { favoriteUi in
                    HStack {
                        Text(favoriteUi.name)
                        Spacer()
                        Button(
                            action: {
                                favoriteUi.favoriteDb.delete()
                                syncFavoritesUi()
                            },
                            label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            },
                        )
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
                .onMove { from, to in
                    moveFavorites(from: from, to: to)
                }
            }
        }
        .navigationTitle("Favorite")
        .onAppear {
            syncFavoritesUi()
        }
    }
    
    private func syncFavoritesUi() {
        favoritesUi = FavoriteDb.selectAllSorted().map { FavoriteUi(favoriteDb: $0) }
    }
    
    private func moveFavorites(from: IndexSet, to: Int) {
        var sortedFavoritesUi = favoritesUi
        from.forEach { fromIdx in
            // Fix crash if single item
            // and ignore same position
            if fromIdx == to {
                return
            }
            let newFromIdx = fromIdx
            let newToIdx = (fromIdx > to ? to : (to - 1))
            sortedFavoritesUi.swapAt(newFromIdx, newToIdx)
        }
        sortedFavoritesUi.enumerated().forEach { idx, favoriteUi in
            favoriteUi.favoriteDb.updateSort(idx)
        }
        syncFavoritesUi()
    }
}

private struct FormAppUi: Hashable {
    let title: String
    let bundle: String
}

@MainActor
private struct FavoriteUi {
    
    let favoriteDb: FavoriteDb
    
    var name: String {
        favoriteDb.buildUiName()
    }
}
