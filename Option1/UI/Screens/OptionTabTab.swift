import SwiftUI
import SwiftData

struct OptionTabTab: View {
    
    @State private var isOptionTabEnabled: Bool = OptionTabManager.instance.isEnabled
    
    @Query private var appsDb: [AppDb]
    
    @Query(sort: \OptionTabPinDb.sort) private var pinsDb: [OptionTabPinDb]
    private var pinsUi: [PinUi] {
        pinsDb.map { pinDb in
            let bundle: String = pinDb.bundle
            return PinUi(
                pinDb: pinDb,
                title: appsDb.first { $0.bundle == bundle }?.name ?? bundle,
            )
        }
    }
    
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
                ForEach(pinsUi, id: \.bundle) { pinUi in
                    HStack {
                        Text(pinUi.title)
                        Spacer()
                        Button(
                            action: {
                                OptionTabPinDb.delete(bundle: pinUi.bundle)
                            },
                            label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        )
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
                .onMove { from, to in
                    movePins(from: from, to: to)
                }
            }
        }
        .navigationTitle("Option-Tab")
    }
    
    private func movePins(from: IndexSet, to: Int) {
        var sortedPinsUi = pinsUi
        from.forEach { fromIdx in
            // Fix crash if single item
            // and ignore same position
            if fromIdx == to {
                return
            }
            let newFromIdx = fromIdx
            let newToIdx = (fromIdx > to ? to : (to - 1))
            sortedPinsUi.swapAt(newFromIdx, newToIdx)
        }
        sortedPinsUi.enumerated().forEach { idx, pinUi in
            pinUi.pinDb.updateSort(idx)
        }
    }
}

private struct PinUi: Hashable {
    
    let pinDb: OptionTabPinDb
    let title: String
    
    var bundle: String {
        pinDb.bundle
    }
}
