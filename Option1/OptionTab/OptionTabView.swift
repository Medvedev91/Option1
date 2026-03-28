import AppKit
import SwiftUI

private let fontSize = 14.0

struct OptionTabView: View {
    
    static let itemHeight = 24.0
    static let itemHeaderPadding = itemHeight / 1.62
    
    let window: NSWindow
    @ObservedObject var data: OptionTabData
    let onCachedWindowFocus: (CachedWindow) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(data.appsUi, id: \.app) { appUi in
                    AppView(
                        appUi: appUi,
                        selectedCachedWindow: data.selectedCachedWindow,
                        onCachedWindowSelected: { cachedWindow in
                            data.selectedCachedWindow = cachedWindow
                        },
                        onCachedWindowFocus: onCachedWindowFocus,
                    )
                }
            }
        }
        .fillMaxSize()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

private struct AppView: View {
    
    let appUi: OptionTabAppUi
    let selectedCachedWindow: CachedWindow?
    let onCachedWindowSelected: (CachedWindow) -> Void
    let onCachedWindowFocus: (CachedWindow) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            
            HStack {
            }
            .frame(height: OptionTabView.itemHeaderPadding)
            
            Text(appUi.app?.localizedName ?? "Other")
                .textAlign(.leading)
                .font(.system(size: fontSize, weight: .heavy))
                .lineLimit(1)
                .frame(height: OptionTabView.itemHeight)
                .padding(.horizontal, 20)
            
            ForEach(appUi.cachedWindows, id: \.self) { cachedWindow in
                CachedWindowView(
                    cachedWindow: cachedWindow,
                    isSelected: cachedWindow == selectedCachedWindow,
                    onCachedWindowSelected: {
                        onCachedWindowSelected(cachedWindow)
                    },
                    onCachedWindowFocus: {
                        onCachedWindowFocus(cachedWindow)
                    },
                )
            }
        }
    }
}

private struct CachedWindowView: View {
    
    let cachedWindow: CachedWindow
    let isSelected: Bool
    let onCachedWindowSelected: () -> Void
    let onCachedWindowFocus: () -> Void

    var body: some View {
        Button(
            action: {
                onCachedWindowFocus()
            },
            label: {
                Text(cachedWindow.title)
                    .textAlign(.leading)
                    .font(.system(size: fontSize, weight: .regular))
                    .lineLimit(1)
                    .frame(height: OptionTabView.itemHeight)
                    .padding(.horizontal, 8)
                    .foregroundColor(isSelected ? .white : .primary)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .circular)
                            .fill(isSelected ? .blue : .clear)
                    )
            }
        )
        .buttonStyle(.plain)
        .contentShape(Rectangle()) // Tap area
        .onHover { isHover in
            if isHover {
                onCachedWindowSelected()
            }
        }
        .padding(.horizontal, 12)
    }
}
