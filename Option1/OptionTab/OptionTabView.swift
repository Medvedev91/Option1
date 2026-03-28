import AppKit
import SwiftUI

private let fontSize = 14.0

struct OptionTabView: View {
    
    static let fullWidth: CGFloat = 800.0
    static let windowsWidth: CGFloat = 600.0
    static let menuWidth: CGFloat = fullWidth - windowsWidth
    
    static let itemHeight = 24.0
    static let itemTwoLinesHeight = 40.0
    static let itemHeaderPadding = itemHeight / 1.62
    
    static let menuIconWidth: CGFloat = 12.0
    static let menuSeparatorLeadingPadding: CGFloat = menuIconWidth / 2
    static let menuSeparatorHeight: CGFloat = itemHeaderPadding
    
    let window: NSWindow
    @ObservedObject var data: OptionTabData
    let onCachedWindowFocus: (CachedWindow) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(data.appsUi, id: \.app) { appUi in
                        AppView(
                            appUi: appUi,
                            selectedCachedWindow: data.selectedCachedWindow,
                            onCachedWindowHover: { cachedWindow in
                                data.selectedCachedWindow = cachedWindow
                            },
                            onCachedWindowFocus: onCachedWindowFocus,
                        )
                    }
                }
                .frame(width: Self.windowsWidth)
            }
            
            VStack(spacing: 0) {
                
                ForEach(MenuBarManager.instance.workspacesUi, id: \.workspaceDb?.id) { workspaceUi in
                    HStack(spacing: 0) {
                        HStack {
                            if workspaceUi.isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            Spacer()
                        }
                        .frame(width: Self.menuIconWidth)
                        
                        Text(workspaceUi.workspaceDb?.name ?? "Shared")
                            .textAlign(.leading)
                            .font(.system(size: fontSize, weight: .regular))
                            .lineLimit(1)
                    }
                    .frame(height: Self.itemHeight)
                }
                
                Divider()
                    .frame(height: Self.menuSeparatorHeight)
                    .padding(.leading, Self.menuSeparatorLeadingPadding)
                    .padding(.trailing)
                
                ForEach(MenuBarManager.instance.bindsUi, id: \.bindDb.id) { bindUi in
                    HStack {
                        VStack(spacing: 0) {
                            Text(bindUi.title)
                                .textAlign(.leading)
                                .font(.system(size: fontSize, weight: .regular))
                                .lineLimit(1)
                            if let subtitle = bindUi.subtitle {
                                Text(subtitle)
                                    .textAlign(.leading)
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 11, weight: .regular))
                                    .lineLimit(1)
                                    .padding(.top, 1)
                                    .padding(.bottom, 2)
                            }
                        }
                    }
                    .frame(height: bindUi.subtitle == nil ? Self.itemHeight : Self.itemTwoLinesHeight)
                    .padding(.leading, Self.menuIconWidth)
                }
                
                Divider()
                    .frame(height: Self.menuSeparatorHeight)
                    .padding(.leading, Self.menuSeparatorLeadingPadding)
                    .padding(.trailing)
                
                Text("Settings")
                    .textAlign(.leading)
                    .font(.system(size: fontSize, weight: .regular))
                    .frame(height: Self.itemHeight)
                    .padding(.leading, Self.menuIconWidth)
            }
            .padding(.top, Self.itemHeaderPadding)
            .frame(width: Self.menuWidth)
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
    let onCachedWindowHover: (CachedWindow?) -> Void
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
                    onCachedWindowHover: { isHover in
                        onCachedWindowHover(isHover ? cachedWindow : nil)
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
    let onCachedWindowHover: (Bool) -> Void
    let onCachedWindowFocus: () -> Void
    
    ///
    
    @State private var isFirstHover = true

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
                    .animation(.linear(duration: 0.05), value: isSelected)
            }
        )
        .buttonStyle(.plain)
        .contentShape(Rectangle()) // Tap area
        .onContinuousHover { hoverPhase in
            switch hoverPhase {
            case .active:
                if !isFirstHover {
                    onCachedWindowHover(true)
                }
                isFirstHover = false
            case .ended:
                isFirstHover = true
                onCachedWindowHover(false)
            }
        }
        .padding(.horizontal, 12)
    }
}
