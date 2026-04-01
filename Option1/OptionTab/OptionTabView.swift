import AppKit
import SwiftUI

private let fontSize = 14.0
private let windowsListItemInnerPadding = 8.0
private let windowsScrollTopId = "WINDOWS-SCROLL-TOP-ID"
private let windowsScrollBottomId = "WINDOWS-SCROLL-BOTTOM-ID"

struct OptionTabView: View {
    
    static let fullWidth: CGFloat = 840.0
    static let windowsWidth: CGFloat = 600.0
    static let menuWidth: CGFloat = fullWidth - windowsWidth
    
    static let itemHeight = 28.0
    static let itemTwoLinesHeight = 40.0
    static let itemHeaderPadding = itemHeight / 1.62
    
    static let menuIconWidth: CGFloat = 20.0
    static let menuDividerHeight: CGFloat = itemHeaderPadding
    static let menuItemOuterTrailingPadding: CGFloat = 12
    
    let window: NSWindow
    @ObservedObject var data: OptionTabData
    let onCachedWindowFocus: (CachedWindow) -> Void
    let closeWindow: () -> Void
    
    ///
    
    @State private var dbMode: OptionTabDbMode = KvDb.selectOptionTabDbMode()
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            
            ScrollView(showsIndicators: false) {
                
                ScrollViewReader { scroll in
                    
                    VStack(spacing: 0) {
                        
                        ZStack {}
                            .id(windowsScrollTopId)
                        
                        switch data.uiMode {
                        case .apps:
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
                        case .history:
                            ZStack {}
                                .frame(height: Self.itemHeaderPadding)
                            ForEach(data.history, id: \.self) { cachedWindow in
                                HistoryItemView(
                                    cachedWindow: cachedWindow,
                                    selectedCachedWindow: data.selectedCachedWindow,
                                    onCachedWindowHover: { cachedWindow in
                                        data.selectedCachedWindow = cachedWindow
                                    },
                                    onCachedWindowFocus: onCachedWindowFocus,
                                )
                            }
                        }
                        
                        ZStack {}
                            .id(windowsScrollBottomId)
                            .frame(height: Self.itemHeaderPadding)
                    }
                    .frame(width: Self.windowsWidth)
                    .onChange(of: data.selectedCachedWindow, initial: true) { _, new in
                        if let new = new {
                            
                            // При скролле мышью докручивать только до ближайшего
                            guard let isOptionTabPressedUpOrDown = HotKeysUtils.isOptionTabPressedUpOrDownOrNil else {
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
                                if let idx = appsUi.firstIndex(of: new) {
                                    if isOptionTabPressedUpOrDown {
                                        let overScrollSize = 4
                                        if idx <= overScrollSize {
                                            scroll.scrollTo(windowsScrollTopId)
                                        } else {
                                            scroll.scrollTo(appsUi[idx - overScrollSize].hashValue)
                                        }
                                    } else {
                                        let overScrollSize = 3
                                        if (appsUi.count - idx) <= overScrollSize {
                                            scroll.scrollTo(windowsScrollBottomId)
                                        } else {
                                            scroll.scrollTo(appsUi[idx + overScrollSize].hashValue)
                                        }
                                    }
                                } else {
                                    scroll.scrollTo(new.hashValue)
                                }
                            }
                        }
                    }
                }
            }

            VStack(spacing: 0) {
                
                HStack {
                    
                    DbModeButton(dbMode: .jk, stateUiMode: $data.uiMode, stateDbMode: $dbMode)
                    DbModeButton(dbMode: .apps, stateUiMode: $data.uiMode, stateDbMode: $dbMode)
                    DbModeButton(dbMode: .history, stateUiMode: $data.uiMode, stateDbMode: $dbMode)

                    Spacer()
                }
                .frame(height: Self.itemHeight)
                .padding(.leading, Self.menuIconWidth)

                MenuDivider()

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
                
                MenuDivider()
                
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
                
                MenuDivider()

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
            RoundedRectangle(cornerRadius: data.isFullHeight ? 0 : 16, style: .continuous)
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
    
    @State private var isFirstHeaderHover = true
    @State private var isHeaderHover = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            
            VStack(spacing: 0) {
                
                if let icon = appUi.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: OptionTabView.itemHeight, height: OptionTabView.itemHeight)
                        .onTapGesture {
                            openApp()
                        }
                }
                
                ZStack {
                    let isPinned = appUi.sort != nil
                    Button(
                        action: {
                            if let bundle = appUi.bundle {
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
                                .padding(.top, 1)
                                .contentShape(Rectangle()) // Tap area
                        },
                    )
                    .buttonStyle(.plain)
                }
                .frame(width: OptionTabView.itemHeight, height: OptionTabView.itemHeight)
            }
            .frame(width: OptionTabView.itemHeight)
            .padding(.leading, 12)
            .padding(.trailing, 2)
            
            VStack(spacing: 0) {
                
                WindowsListItemButton(
                    text: appUi.app?.localizedName ?? "Other",
                    fontWeight: .heavy,
                    isSelected: isHeaderHover && selectedCachedWindow == nil,
                    onClick: {
                        openApp()
                    },
                )
                .onContinuousHover { hoverPhase in
                    // Если список не входит в экран, а курсор в зоне прокрутки,
                    // при автоматической докрутке за выбранным элементом
                    // сработает данный метод и открутит экран назад.
                    if HotKeysUtils.isOptionTabPressedUpOrDownOrNil != nil {
                        return
                    }
                    
                    switch hoverPhase {
                    case .active:
                        if !isFirstHeaderHover {
                            onCachedWindowHover(nil)
                            isHeaderHover = true
                        }
                        isFirstHeaderHover = false
                    case .ended:
                        isFirstHeaderHover = true
                        isHeaderHover = false
                    }
                }
                
                let cachedWindows = appUi.cachedWindows
                ForEach(cachedWindows, id: \.self) { cachedWindow in
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
                    .id(cachedWindow.hashValue)
                }
            }
        }
        .padding(.top, OptionTabView.itemHeaderPadding)
    }
    
    private func openApp() {
        if let cachedWindow = appUi.cachedWindows.first {
            onCachedWindowFocus(cachedWindow)
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
        WindowsListItemButton(
            text: cachedWindow.title,
            fontWeight: .regular,
            isSelected: isSelected,
            onClick: {
                onCachedWindowFocus()
            },
        )
        .onContinuousHover { hoverPhase in
            // Если список не входит в экран, а курсор в зоне прокрутки,
            // при автоматической докрутке за выбранным элементом
            // сработает данный метод и открутит экран назад.
            if HotKeysUtils.isOptionTabPressedUpOrDownOrNil != nil {
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

private struct WindowsListItemButton: View {
    
    let text: String
    let fontWeight: Font.Weight
    let isSelected: Bool
    let onClick: () -> Void
    
    var body: some View {
        Button(
            action: {
                onClick()
            },
            label: {
                Text(text)
                    .textAlign(.leading)
                    .font(.system(size: fontSize, weight: fontWeight))
                    .lineLimit(1)
                    .frame(height: OptionTabView.itemHeight)
                    .padding(.horizontal, windowsListItemInnerPadding)
                    .foregroundColor(isSelected ? .white : .primary)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .circular)
                            .fill(isSelected ? .blue : .clear)
                    )
            }
        )
        .buttonStyle(.plain)
        .contentShape(Rectangle()) // Tap area
    }
}

private struct HistoryItemView: View {
    
    let cachedWindow: CachedWindow
    let selectedCachedWindow: CachedWindow?
    let onCachedWindowHover: (CachedWindow?) -> Void
    let onCachedWindowFocus: (CachedWindow) -> Void
    
    ///
    
    private let imageSize = OptionTabView.itemHeight
    
    var body: some View {
        HStack(spacing: 0) {
            
            ZStack {
                if let icon = cachedWindow.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: imageSize, height: imageSize)
                        .onTapGesture {
                            onCachedWindowFocus(cachedWindow)
                        }
                }
            }
            .frame(width: imageSize)
            .padding(.leading, 16)
            .padding(.trailing, 8)
            
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
            .id(cachedWindow.hashValue)
        }
    }
}

private struct MenuDivider: View {
    
    var body: some View {
        Divider()
            .frame(height: OptionTabView.menuDividerHeight)
            .padding(.leading, OptionTabView.menuIconWidth)
            .padding(.trailing, 24)
    }
}

private struct DbModeButton: View {
    
    let dbMode: OptionTabDbMode
    @Binding var stateUiMode: OptionTabUiMode
    @Binding var stateDbMode: OptionTabDbMode
    
    ///

    private var text: String {
        switch dbMode {
        case .apps:
            "Apps"
        case .history:
            "History"
        case .jk:
            "JK"
        }
    }
    
    var body: some View {
        Button(text) {
            stateUiMode = switch dbMode {
            case .apps: .apps
            case .history: .history
            case .jk: stateUiMode
            }
            stateDbMode = dbMode
            KvDb.upsertOptionTabDbMode(dbMode)
        }
        .buttonStyle(.plain)
        .foregroundColor(stateDbMode == dbMode ? .primary : .secondary)
        .font(.system(size: fontSize))
    }
}
