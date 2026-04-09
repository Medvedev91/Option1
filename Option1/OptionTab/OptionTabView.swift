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
    
    @ObservedObject private var badgesManager = BadgesManager.instance
    
    @State private var isModeHovered = false
    
    let window: NSWindow
    @ObservedObject var data: OptionTabData
    
    ///
    
    @State private var dbMode: OptionTabDbMode = KvDb.selectOptionTabDbMode()
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            
            ScrollView(showsIndicators: false) {
                
                ScrollViewReader { scroll in
                    
                    VStack(spacing: 0) {
                        
                        ZStack {}
                            .id(windowsScrollTopId)
                            .padding(.bottom, data.windowSize.safeAreaTop)
                        
                        switch data.uiMode {
                        case .apps:
                            ForEach(data.appsUi, id: \.app) { appUi in
                                AppView(
                                    optionTabData: data,
                                    appUi: appUi,
                                )
                            }
                        case .history:
                            ZStack {}
                                .frame(height: Self.itemHeaderPadding)
                            ForEach(data.history, id: \.self) { cachedWindow in
                                HistoryItemView(
                                    optionTabData: data,
                                    cachedWindow: cachedWindow,
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
                            
                            let windows: [CachedWindow] = switch data.uiMode {
                            case .apps:
                                data.appsUi.flatMap(\.cachedWindows)
                            case .history:
                                data.history
                            }
                            if new == windows.first {
                                // Для первого элемента нужно прокрутить в
                                // самый верх чтобы был виден заголовок.
                                scroll.scrollTo(windowsScrollTopId)
                            } else if new == windows.last {
                                // Для последнего надо докрутить в самый низ для отступа.
                                scroll.scrollTo(windowsScrollBottomId)
                            } else {
                                // Прокрутка вперед актуальна если окно не влезает в высоту
                                if let idx = windows.firstIndex(of: new) {
                                    if isOptionTabPressedUpOrDown {
                                        let overScrollSize = 4
                                        if idx <= overScrollSize {
                                            scroll.scrollTo(windowsScrollTopId)
                                        } else {
                                            scroll.scrollTo(windows[idx - overScrollSize].hashValue)
                                        }
                                    } else {
                                        let overScrollSize = 3
                                        if (windows.count - idx) <= overScrollSize {
                                            scroll.scrollTo(windowsScrollBottomId)
                                        } else {
                                            scroll.scrollTo(windows[idx + overScrollSize].hashValue)
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
                    
                    DbModeButton(optionTabData: data, dbMode: .jk, stateDbMode: $dbMode)
                    DbModeButton(optionTabData: data, dbMode: .apps, stateDbMode: $dbMode)
                    DbModeButton(optionTabData: data, dbMode: .history, stateDbMode: $dbMode)
                        .alert(
                            "",
                            isPresented: $data.isJkInfoPresented,
                            actions: {},
                            message: { Text("Vim-inspired JK mode is a combination of Apps and History. Press Option-Tab to Apps mode, Option-J to History.") }
                        )
                    
                    if isModeHovered {
                        Button(
                            action: {
                                data.isJkInfoPresented = true
                            },
                            label: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.secondary)
                            },
                        )
                        .buttonStyle(.borderless)
                    }
                    
                    Spacer()
                    
                    Button(
                        action: {
                            data.isKeepJumpsGlobal = KvDb.upsertIsKeepJumpsGlobal(!data.isKeepJumpsGlobal)
                            data.isKeepShortcutsGlobalInfoPresented = true
                        },
                        label: {
                            Image(systemName: "keyboard")
                                .font(.system(size: fontSize, weight: .regular))
                                .foregroundColor(data.isKeepJumpsGlobal ? .primary : .secondary)
                        },
                    )
                    .buttonStyle(.borderless)
                    .help("Keep Shortcuts Global")
                    .alert(
                        "",
                        isPresented: $data.isKeepShortcutsGlobalInfoPresented,
                        actions: {},
                        message: { Text("\(data.isKeepJumpsGlobal ? "Enabled" : "Disabled")!\n\nThis feature keeps shortcuts for windows active even if Option-Tab is closed.") }
                    )
                }
                .frame(height: Self.itemHeight)
                .padding(.leading, Self.menuIconWidth)
                .padding(.trailing, 21)
                .padding(.top, data.windowSize.safeAreaTop)
                .onHover { isHovered in
                    self.isModeHovered = isHovered
                }
                
                MenuDivider()
                
                ForEach(data.workspacesUi, id: \.menuBarWorkspaceUi.workspaceDb?.id) { workspaceUi in
                    MenuItemView(
                        onClick: {
                            workspaceUi.onClick()
                        },
                        content: { isHover in
                            HStack(spacing: 0) {
                                HStack(spacing: 0) {
                                    if workspaceUi.menuBarWorkspaceUi.isSelected {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(isHover ? .white : .primary)
                                            .font(.system(size: 11, weight: .semibold))
                                            .padding(.leading, 4)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .frame(width: Self.menuIconWidth)
                                
                                Text(workspaceUi.menuBarWorkspaceUi.workspaceDb?.name ?? "Shared")
                                    .foregroundColor(isHover ? .white : .primary)
                                    .font(.system(size: fontSize, weight: .regular))
                                    .lineLimit(1)
                                
                                if data.workspacesUi.count > 1 {
                                    JumpButton(jumpKey: workspaceUi.jumpKey, color: isHover ? .white : .secondary)
                                        .padding(.leading, 8)
                                }
                                
                                Spacer(minLength: 0)
                            }
                            .frame(height: Self.itemHeight)
                        },
                    )
                }
                
                MenuDivider()
                
                ForEach(data.bindsUi, id: \.bindDb.id) { bindUi in
                    MenuItemView(
                        onClick: {
                            data.closeWindow()
                            HotKeysUtils.handleKey(key: bindUi.key)
                        },
                        content: { isHover in
                            HStack(spacing: 0) {
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(bindUi.title)
                                        .font(.system(size: fontSize, weight: .regular))
                                        .foregroundColor(isHover ? .white : .primary)
                                        .lineLimit(1)
                                    if let subtitle = bindUi.subtitle {
                                        Text(subtitle)
                                            .foregroundColor(isHover ? .white : .secondary)
                                            .font(.system(size: 11, weight: .regular))
                                            .lineLimit(1)
                                            .padding(.top, 1)
                                            .padding(.bottom, 2)
                                    }
                                }
                                
                                if let badge = badgesManager.dictionary[bindUi.bindDb.bundle] {
                                    ZStack {
                                        Text(badge)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 18, height: 18)
                                    .background(Circle().fill(.red))
                                    .padding(.leading, 6)
                                    .padding(.trailing, 6)
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
                        data.closeWindow()
                        FavoriteTabUtils.instance.needToShow = true
                        WindowsManager.openApplicationByBundle(Bundle.main.bundleIdentifier!)
                    },
                    content: { isHover in
                        HStack(spacing: 0) {
                            
                            Text("Favourites")
                                .foregroundColor(isHover ? .white : .secondary)
                                .font(.system(size: 11, weight: .semibold))
                            
                            Spacer(minLength: 0)
                            
                            if isHover {
                                Image(systemName: "plus")
                                    .foregroundColor(isHover ? .white : .secondary)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                        }
                        .frame(height: Self.itemHeight)
                        .padding(.leading, Self.menuIconWidth)
                        .padding(.trailing, 10)
                    },
                )
                
                ForEach(data.favoritesUi, id: \.favoriteDb.id) { favoriteUi in
                    MenuItemView(
                        onClick: {
                            favoriteUi.onClick()
                        },
                        content: { isHover in
                            HStack(spacing: 0) {
                                
                                Spacer(minLength: 0)
                                    .frame(width: Self.menuIconWidth - 2)
                                
                                let icon = favoriteUi.icon
                                if let icon = icon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                }
                                
                                Text(favoriteUi.title)
                                    .foregroundColor(isHover ? .white : .primary)
                                    .padding(.leading, icon == nil ? 2 : 6)
                                
                                let badge = badgesManager.dictionary[favoriteUi.favoriteDb.bundle]
                                
                                JumpButton(jumpKey: favoriteUi.jumpKey, color: isHover ? .white : .secondary)
                                    .padding(.leading, badge == nil ? 8 : 4)
                                
                                if let badge = badge {
                                    ZStack {
                                        Text(badge)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 18, height: 18)
                                    .background(Circle().fill(.red))
                                    .padding(.leading, 6)
                                    .padding(.trailing, 6)
                                }
                                
                                Spacer(minLength: 0)
                            }
                            .frame(height: Self.itemHeight)
                        },
                    )
                }
                
                MenuDivider()
                
                MenuItemView(
                    onClick: {
                        data.closeWindow()
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
                
                if data.showDonations {
                    MenuItemView(
                        onClick: {
                            data.closeWindow()
                            DonationsAlertUtils.instance.needToShow = true
                            WindowsManager.openApplicationByBundle(Bundle.main.bundleIdentifier!)
                        },
                        content: { isHover in
                            Text("Donations")
                                .textAlign(.leading)
                                .foregroundColor(isHover ? .white : .red)
                                .font(.system(size: fontSize, weight: .regular))
                                .frame(height: Self.itemHeight)
                                .padding(.leading, Self.menuIconWidth)
                        },
                    )
                }
            }
            .padding(.top, Self.itemHeaderPadding)
            .frame(width: Self.menuWidth)
        }
        .fillMaxSize()
        .background(
            // Если все элементы не влазят в экран, углы лучше сделать прямоугольными,
            // будет нагляднее что нужно докручивать вниз.
            RoundedRectangle(cornerRadius: data.windowSize.isFullHeight ? 0 : 16, style: .continuous)
                .fill(.thinMaterial)
        )
        .onChange(of: data.windowSize.nsRect) { _, newValue in
            NSAnimationContext.runAnimationGroup({ context in
                context.timingFunction = CAMediaTimingFunction(name: .default)
                window.animator().setFrame(
                    newValue,
                    display: false,
                    animate: data.animateWindowResize,
                )
            }, completionHandler: {
            })
        }
    }
}

private struct AppView: View {
    
    @StateObject var optionTabData: OptionTabData
    let appUi: OptionTabAppUi
    
    ///
    
    @ObservedObject private var badgesManager = BadgesManager.instance
    @State private var isAppHovered = false
    @State private var isPinWrapperHovered = false
    
    private var badge: String? {
        guard let bundle = appUi.bundle else {
            return nil
        }
        return badgesManager.dictionary[bundle]
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            
            HStack(spacing: 0) {
                
                ZStack {
                    let isPinned = appUi.sort != nil
                    if isPinWrapperHovered || ((badge == nil) && (isAppHovered || isPinned)) {
                        Button(
                            action: {
                                if let bundle = appUi.bundle {
                                    if isPinned {
                                        OptionTabPinDb.delete(bundle: bundle)
                                    } else {
                                        OptionTabPinDb.upsertToTop(bundle: bundle)
                                    }
                                    withAnimation {
                                        self.optionTabData.rebuildAppsUi()
                                    }
                                }
                            },
                            label: {
                                Image(systemName: isPinned ? "pin.fill" : "pin")
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundColor(.primary)
                                    .padding(.top, 1)
                                    .padding(.leading, 1)
                                    .contentShape(Rectangle()) // Tap area
                            },
                        )
                        .buttonStyle(.plain)
                    }
                    
                    if !isPinWrapperHovered,
                       let badge = badge {
                        ZStack {
                            Text(badge)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 23, height: 23)
                        .background(Circle().fill(.red))
                    }
                }
                .frame(width: 28, height: OptionTabView.itemHeight)
                .padding(.leading, 4)
                .padding(.trailing, 1)
                .contentShape(Rectangle()) // Hover area
                .onHover { isHovered in
                    isPinWrapperHovered = isHovered
                }

                if let icon = appUi.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: OptionTabView.itemHeight, height: OptionTabView.itemHeight)
                        .onTapGesture {
                            if let cachedWindow = appUi.cachedWindows.first {
                                optionTabData.onCachedWindowFocus(cachedWindow)
                            }
                        }
                }
            }
            .padding(.trailing, 2)
            
            VStack(spacing: 0) {
                let cachedWindows = appUi.cachedWindows
                ForEach(cachedWindows, id: \.self) { cachedWindow in
                    CachedWindowView(
                        optionTabData: optionTabData,
                        cachedWindow: cachedWindow,
                        isSelected: cachedWindow == optionTabData.selectedCachedWindow,
                        onCachedWindowHover: { isHover in
                            optionTabData.selectedCachedWindow = isHover ? cachedWindow : nil
                        },
                    )
                    .id(cachedWindow.hashValue)
                }
            }
        }
        .padding(.top, OptionTabView.itemHeaderPadding)
        .onHover { isHovered in
            isAppHovered = isHovered
        }
    }
}

private struct CachedWindowView: View {
    
    @StateObject var optionTabData: OptionTabData
    let cachedWindow: CachedWindow
    let isSelected: Bool
    let onCachedWindowHover: (Bool) -> Void
    
    ///
    
    @State private var isFirstHover = true
    
    var body: some View {
        WindowsListItemButton(
            text: cachedWindow.title,
            jumpKey: optionTabData.jumpCachedWindowKeyMap[cachedWindow.axuiElement.hashValue],
            fontWeight: .regular,
            isSelected: isSelected,
            onClick: {
                optionTabData.onCachedWindowFocus(cachedWindow)
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
    let jumpKey: OptionTabJumpKey?
    let fontWeight: Font.Weight
    let isSelected: Bool
    let onClick: () -> Void
    
    var body: some View {
        Button(
            action: {
                onClick()
            },
            label: {
                HStack(spacing: 0) {
                    
                    Text(text)
                        .font(.system(size: fontSize, weight: fontWeight))
                        .lineLimit(1)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    if let jumpKey = jumpKey {
                        JumpButton(jumpKey: jumpKey, color: isSelected ? .white : .secondary)
                            .padding(.leading, 8)
                    }
                    
                    Spacer(minLength: 0)
                }
                .frame(height: OptionTabView.itemHeight)
                .padding(.horizontal, windowsListItemInnerPadding)
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
    
    @StateObject var optionTabData: OptionTabData
    let cachedWindow: CachedWindow
    
    ///
    
    @ObservedObject private var badgesManager = BadgesManager.instance
    private let imageSize = OptionTabView.itemHeight
    private let badgeSize = 23.0

    var body: some View {
        HStack(spacing: 0) {
            
            ZStack {
                if let badge = badgesManager.dictionary[cachedWindow.appBundle] {
                    ZStack {
                        Text(badge)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .fillMaxSize()
                    .background(Circle().fill(.red))
                }
            }
            .frame(width: badgeSize, height: badgeSize)
            .padding(.leading, 6)

            ZStack {
                if let icon = cachedWindow.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: imageSize, height: imageSize)
                        .onTapGesture {
                            optionTabData.onCachedWindowFocus(cachedWindow)
                        }
                }
            }
            .frame(width: imageSize)
            .padding(.leading, 4)
            
            CachedWindowView(
                optionTabData: optionTabData,
                cachedWindow: cachedWindow,
                isSelected: cachedWindow == optionTabData.selectedCachedWindow,
                onCachedWindowHover: { isHover in
                    optionTabData.selectedCachedWindow = isHover ? cachedWindow : nil
                },
            )
            .id(cachedWindow.hashValue)
            .padding(.leading, 2)
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
    
    @StateObject var optionTabData: OptionTabData
    let dbMode: OptionTabDbMode
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
            optionTabData.uiMode = switch dbMode {
            case .apps: .apps
            case .history: .history
            case .jk: optionTabData.uiMode
            }
            stateDbMode = dbMode
            KvDb.upsertOptionTabDbMode(dbMode)
            optionTabData.animateWindowResize = true
        }
        .buttonStyle(.plain)
        .foregroundColor(stateDbMode == dbMode ? .primary : .secondary)
        .font(.system(size: fontSize))
    }
}

private struct JumpButton: View {
    
    let jumpKey: OptionTabJumpKey
    let color: Color
    
    var body: some View {
        Text(jumpKey.text)
            .font(.system(size: fontSize, weight: .regular))
            .foregroundColor(color)
    }
}
