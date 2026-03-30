import AppKit
import SwiftUI

private let fontSize = 14.0
private let leadingBarWidth = 52.0
private let windowsScrollTopId = "WINDOWS-SCROLL-TOP-ID"
private let windowsScrollBottomId = "WINDOWS-SCROLL-BOTTOM-ID"

struct OptionTabView: View {
    
    static let fullWidth: CGFloat = 840.0
    static let windowsWidth: CGFloat = 600.0
    static let menuWidth: CGFloat = fullWidth - windowsWidth
    
    static let itemHeight = 24.0
    static let itemTwoLinesHeight = 40.0
    static let itemHeaderPadding = itemHeight / 1.62
    
    static let menuIconWidth: CGFloat = 20.0
    static let menuSeparatorHeight: CGFloat = itemHeaderPadding
    static let menuItemOuterTrailingPadding: CGFloat = 12
    
    let window: NSWindow
    @ObservedObject var data: OptionTabData
    let onCachedWindowFocus: (CachedWindow) -> Void
    let closeWindow: () -> Void
    let isFullHeight: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            
            ScrollView(showsIndicators: false) {
                
                ScrollViewReader { scroll in
                    
                    VStack(spacing: 0) {
                        
                        ZStack {}
                            .id(windowsScrollTopId)
                        
                        ForEach(data.appsUi, id: \.app) { appUi in
                            AppView(
                                appUi: appUi,
                                updateAppsUi: {
                                    data.rebuildAppsUi()
                                },
                                selectedCachedWindow: data.selectedCachedWindow,
                                onCachedWindowHover: { cachedWindow in
                                    data.selectedCachedWindow = cachedWindow
                                },
                                onCachedWindowFocus: onCachedWindowFocus,
                            )
                        }
                        
                        ZStack {}
                            .id(windowsScrollBottomId)
                            .frame(height: Self.itemHeaderPadding)
                    }
                    .frame(width: Self.windowsWidth)
                    .onChange(of: data.selectedCachedWindow) { _, new in
                        if let new = new {
                            
                            // Докручивать нужно только при скролле руками
                            if !HotKeysUtils.isOptionTabPressed {
                                scroll.scrollTo(new.hashValue)
                                return
                            }
                            
                            let appsUi = data.appsUi.flatMap(\.cachedWindows)
                            if new == appsUi.first {
                                // Для первого элемента нужно прокрутить в
                                // самый верх чтобы был виден заголовок.
                                scroll.scrollTo(windowsScrollTopId)
                            } else if new == appsUi.last {
                                // Для последнего надо докрутить в самый низ для отступа.
                                scroll.scrollTo(windowsScrollBottomId)
                            } else {
                                // Прокрутка вперед актуальна если окно не влезает в высоту
                                if let idx = appsUi.firstIndex(of: new), (idx + 2) < appsUi.count {
                                    scroll.scrollTo(appsUi[idx + 2].hashValue)
                                } else if let idx = appsUi.firstIndex(of: new), (idx + 1) < appsUi.count {
                                    scroll.scrollTo(appsUi[idx + 1].hashValue)
                                } else {
                                    scroll.scrollTo(new.hashValue)
                                }
                            }
                        }
                    }
                }
            }

            VStack(spacing: 0) {
                
                ForEach(MenuBarManager.instance.workspacesUi, id: \.workspaceDb?.id) { workspaceUi in
                    MenuItemView(
                        onClick: {
                            closeWindow()
                            MenuBarManager.instance.setWorkspaceDb(workspaceUi.workspaceDb)
                        },
                        content: { isHover in
                            HStack(spacing: 0) {
                                HStack(spacing: 0) {
                                    if workspaceUi.isSelected {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(isHover ? .white : .primary)
                                            .font(.system(size: 11, weight: .semibold))
                                            .padding(.leading, 4)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .frame(width: Self.menuIconWidth)
                                
                                Text(workspaceUi.workspaceDb?.name ?? "Shared")
                                    .foregroundColor(isHover ? .white : .primary)
                                    .textAlign(.leading)
                                    .font(.system(size: fontSize, weight: .regular))
                                    .lineLimit(1)
                            }
                            .frame(height: Self.itemHeight)
                        },
                    )
                }
                
                Divider()
                    .frame(height: Self.menuSeparatorHeight)
                    .padding(.leading, Self.menuIconWidth)
                    .padding(.trailing, 24)
                
                ForEach(MenuBarManager.instance.bindsUi, id: \.bindDb.id) { bindUi in
                    MenuItemView(
                        onClick: {
                            closeWindow()
                            HotKeysUtils.handleRun(key: bindUi.key)
                        },
                        content: { isHover in
                            HStack(spacing: 0) {
                                VStack(spacing: 0) {
                                    Text(bindUi.title)
                                        .textAlign(.leading)
                                        .font(.system(size: fontSize, weight: .regular))
                                        .foregroundColor(isHover ? .white : .primary)
                                        .lineLimit(1)
                                    if let subtitle = bindUi.subtitle {
                                        Text(subtitle)
                                            .textAlign(.leading)
                                            .foregroundColor(isHover ? .white : .secondary)
                                            .font(.system(size: 11, weight: .regular))
                                            .lineLimit(1)
                                            .padding(.top, 1)
                                            .padding(.bottom, 2)
                                    }
                                }
                                Spacer(minLength: 0)
                                Text(bindUi.badge)
                                    .foregroundColor(isHover ? .white : .primary)
                                    .font(.system(size: 11, weight: .semibold))
                                    .padding(.trailing, 6)
                            }
                            .frame(height: bindUi.subtitle == nil ? Self.itemHeight : Self.itemTwoLinesHeight)
                            .padding(.leading, Self.menuIconWidth)
                            .padding(.trailing, 6)
                        },
                    )
                }
                
                Divider()
                    .frame(height: Self.menuSeparatorHeight)
                    .padding(.leading, Self.menuIconWidth)
                    .padding(.trailing, 24)
                
                MenuItemView(
                    onClick: {
                        closeWindow()
                        WindowsManager.openApplicationByBundle(Bundle.main.bundleIdentifier!)
                    },
                    content: { isHover in
                        Text("Settings")
                            .textAlign(.leading)
                            .foregroundColor(isHover ? .white : .primary)
                            .font(.system(size: fontSize, weight: .regular))
                            .frame(height: Self.itemHeight)
                            .padding(.leading, Self.menuIconWidth)
                    },
                )
            }
            .padding(.top, Self.itemHeaderPadding)
            .frame(width: Self.menuWidth)
        }
        .fillMaxSize()
        .background(
            // Если все элементы не влазят в экран, углы лучше сделать прямоугольными,
            // будет нагляднее что нужно докручивать вниз.
            RoundedRectangle(cornerRadius: isFullHeight ? 0 : 16, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

private struct AppView: View {
    
    let appUi: OptionTabAppUi
    let updateAppsUi: () -> Void
    let selectedCachedWindow: CachedWindow?
    let onCachedWindowHover: (CachedWindow?) -> Void
    let onCachedWindowFocus: (CachedWindow) -> Void
    
    ///
    
    var body: some View {
        VStack(spacing: 0) {
            
            HStack {
            }
            .frame(height: OptionTabView.itemHeaderPadding)
            
            HStack(spacing: 0) {
                
                ZStack {
                    if let icon = appUi.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                }
                .frame(width: leadingBarWidth)
                
                Text(appUi.app?.localizedName ?? "Other")
                    .font(.system(size: fontSize, weight: .heavy))
                    .lineLimit(1)
                
                Spacer()
            }
            .frame(height: OptionTabView.itemHeight)
            
            let cachedWindows = appUi.cachedWindows
            ForEach(cachedWindows, id: \.self) { cachedWindow in
                CachedWindowView(
                    cachedWindow: cachedWindow,
                    isSelected: cachedWindow == selectedCachedWindow,
                    appUiForPinButton: cachedWindows.first == cachedWindow ? appUi : nil,
                    updateAppsUi: updateAppsUi,
                    onCachedWindowHover: { isHover in
                        onCachedWindowHover(isHover ? cachedWindow : nil)
                    },
                    onCachedWindowFocus: {
                        onCachedWindowFocus(cachedWindow)
                    },
                )
                .id(cachedWindow.hashValue)
            }
        }
    }
}

private struct CachedWindowView: View {
    
    let cachedWindow: CachedWindow
    let isSelected: Bool
    let appUiForPinButton: OptionTabAppUi?
    let updateAppsUi: () -> Void
    let onCachedWindowHover: (Bool) -> Void
    let onCachedWindowFocus: () -> Void
    
    ///
    
    @State private var isFirstHover = true
    private let innerPadding = 8.0
    
    var body: some View {
        HStack(spacing: 0) {
            
            HStack(spacing: 0) {
                if let appUiForPinButton = appUiForPinButton {
                    let isPinned = appUiForPinButton.sort != nil
                    Button(
                        action: {
                            if let bundle = appUiForPinButton.bundle {
                                if isPinned {
                                    OptionTabPinDb.delete(bundle: bundle)
                                } else {
                                    OptionTabPinDb.upsertToTop(bundle: bundle)
                                }
                                withAnimation {
                                    updateAppsUi()
                                }
                            }
                        },
                        label: {
                            Image(systemName: isPinned ? "pin.fill" : "pin")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                                .padding(.top, 1)
                                .contentShape(Rectangle()) // Tap area
                        },
                    )
                    .buttonStyle(.plain)
                }
            }
            .frame(width: leadingBarWidth - innerPadding)

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
                        .padding(.horizontal, innerPadding)
                        .foregroundColor(isSelected ? .white : .primary)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .circular)
                                .fill(isSelected ? .blue : .clear)
                        )
                    // .animation(.linear(duration: 0.05), value: isSelected)
                }
            )
            .buttonStyle(.plain)
            .contentShape(Rectangle()) // Tap area
            .onContinuousHover { hoverPhase in
                // Если список не входит в экран, а курсор в зоне прокрутки,
                // при автоматической докрутке за выбранным элементом
                // сработает данный метод и открутит экран назад.
                if HotKeysUtils.isOptionTabPressed {
                    return
                }
                
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
        }
    }
}

private struct MenuItemView<Content: View>: View {
    
    let onClick: () -> Void
    @ViewBuilder let content: (_ isHover: Bool) -> Content
    
    ///
    
    @State private var isFirstHover: Bool = true
    @State private var isHover: Bool = false

    var body: some View {
        Button(
            action: {
                onClick()
            },
            label: {
                content(isHover)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .circular)
                            .fill(isHover ? .blue : .clear)
                    )
                    .animation(.linear(duration: 0.05), value: isHover)
                    .padding(.trailing, OptionTabView.menuItemOuterTrailingPadding)
            },
        )
        .buttonStyle(.plain)
        .contentShape(Rectangle()) // Tap area
        .onContinuousHover { hoverPhase in
            switch hoverPhase {
            case .active:
                if !isFirstHover {
                    isHover = true
                }
                isFirstHover = false
            case .ended:
                isFirstHover = true
                isHover = false
            }
        }
    }
}
