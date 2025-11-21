import Foundation

#if os(macOS)
    import AppKit

    @MainActor
    class MainViewController: NSViewController {
        private var wallpaperEngine: WallpaperEngine
        private var wallpaperManager: WallpaperManager

        // UI Components
        private var toolbar: NSToolbar!
        private var togglePauseButton: NSButton!
        private var collectionView: NSCollectionView!
        private var scrollView: NSScrollView!
        private var inspectorView: InspectorView!
        private var splitView: NSSplitView!

        // State
        var selectedWallpaper: WallpaperItem?
        var currentAppliedWallpaper: WallpaperItem?
        var isInspectorVisible: Bool = false

        // Constants
        private let inspectorMinWidth: CGFloat = 200
        private let inspectorMaxWidth: CGFloat = 400
        private let inspectorWidthKey = "InspectorWidth"

        init(wallpaperEngine: WallpaperEngine, wallpaperManager: WallpaperManager) {
            self.wallpaperEngine = wallpaperEngine
            self.wallpaperManager = wallpaperManager
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func loadView() {
            self.view = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 600))
            self.view.wantsLayer = true
            self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            setupToolbar()
            setupSplitView()
            setupCollectionView()
            setupInspector()
            setupClickGesture()

            // Auto-play logic: last played or first wallpaper
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.autoPlayWallpaperIfNeeded()
            }
        }

        private func setupToolbar() {
            toolbar = NSToolbar(identifier: "MainToolbar")
            toolbar.delegate = self

            // Load display mode from settings
            let settings = AppSettings.load()
            toolbar.displayMode = settings.showToolbarLabels ? .iconAndLabel : .iconOnly

            if let window = view.window {
                window.toolbar = toolbar
                window.titleVisibility = .hidden
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, let window = self.view.window else { return }
                    window.toolbar = self.toolbar
                    window.titleVisibility = .hidden
                }
            }
        }

        private func setupSplitView() {
            splitView = NSSplitView(frame: view.bounds)
            splitView.isVertical = true
            splitView.autoresizingMask = [.width, .height]
            splitView.dividerStyle = .thin
            splitView.delegate = self
            view.addSubview(splitView)
        }

        private func setupCollectionView() {
            let flowLayout = NSCollectionViewFlowLayout()
            flowLayout.itemSize = NSSize(width: 200, height: 180)
            flowLayout.sectionInset = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            flowLayout.minimumInteritemSpacing = 20
            flowLayout.minimumLineSpacing = 20

            collectionView = NSCollectionView()
            collectionView.collectionViewLayout = flowLayout
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.isSelectable = true
            collectionView.allowsMultipleSelection = false
            collectionView.backgroundColors = [.clear]

            collectionView.register(
                WallpaperCollectionViewItem.self,
                forItemWithIdentifier: WallpaperCollectionViewItem.identifier
            )

            scrollView = NSScrollView()
            scrollView.documentView = collectionView
            scrollView.hasVerticalScroller = true
            scrollView.autoresizingMask = [.width, .height]

            splitView.addArrangedSubview(scrollView)

            wallpaperManager.loadWallpapers()
            collectionView.reloadData()
        }

        private func updateCollectionViewLayout() {
            guard
                let flowLayout = collectionView.collectionViewLayout as? NSCollectionViewFlowLayout
            else { return }

            // Calculate available width
            let availableWidth =
                scrollView.bounds.width - flowLayout.sectionInset.left
                - flowLayout.sectionInset.right

            // Calculate item width to fit nicely (at least 1 column, maximum what fits)
            let minItemWidth: CGFloat = 180
            let maxItemWidth: CGFloat = 220
            let spacing = flowLayout.minimumInteritemSpacing

            // Calculate how many columns can fit
            var columns = max(1, Int((availableWidth + spacing) / (minItemWidth + spacing)))
            let itemWidth = (availableWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)

            // If items would be too large, reduce columns
            if itemWidth > maxItemWidth {
                columns = max(1, Int((availableWidth + spacing) / (maxItemWidth + spacing)))
                let adjustedWidth =
                    (availableWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
                flowLayout.itemSize = NSSize(width: adjustedWidth, height: adjustedWidth * 0.9)
            } else {
                flowLayout.itemSize = NSSize(width: itemWidth, height: itemWidth * 0.9)
            }

            flowLayout.invalidateLayout()
        }

        private func setupInspector() {
            // Load saved width or use default
            let savedWidth = UserDefaults.standard.float(forKey: inspectorWidthKey)
            let defaultWidth = savedWidth > 0 ? CGFloat(savedWidth) : 250

            inspectorView = InspectorView(
                frame: NSRect(x: 0, y: 0, width: defaultWidth, height: 600))
            inspectorView.delegate = self

            splitView.addArrangedSubview(inspectorView)

            // Set holding priority to prevent inspector from being compressed
            inspectorView.setContentHuggingPriority(.required, for: .horizontal)
            inspectorView.setContentCompressionResistancePriority(.required, for: .horizontal)

            // Initially collapsed
            inspectorView.isHidden = true
        }

        override func viewDidAppear() {
            super.viewDidAppear()

            // Collapse inspector initially
            splitView.setPosition(splitView.bounds.width, ofDividerAt: 0)

            // Initialize collection view layout
            updateCollectionViewLayout()
        }

        private func autoPlayWallpaperIfNeeded() {
            // Only auto-play if wallpaper is enabled
            guard wallpaperEngine.isEnabled else { return }

            // Try to restore last wallpaper
            if let lastWallpaper = wallpaperEngine.getLastWallpaper(),
                wallpaperManager.wallpapers.contains(where: { $0.id == lastWallpaper.id })
            {
                applyWallpaper(lastWallpaper)
                return
            }

            // Otherwise, play first available wallpaper (prioritized by favorites/recent)
            if let firstWallpaper = wallpaperManager.getFirstWallpaper() {
                applyWallpaper(firstWallpaper)
            }
        }

        private func setupClickGesture() {
            // Use mouseDown override instead of gesture recognizer to avoid conflicts
        }

        override func mouseDown(with event: NSEvent) {
            super.mouseDown(with: event)

            let location = event.locationInWindow
            let viewLocation = view.convert(location, from: nil)
            let hitView = view.hitTest(viewLocation)

            // If click is outside collection view and inspector, hide inspector
            if hitView != nil && hitView != collectionView && hitView != inspectorView
                && !isSubviewOf(hitView, parent: collectionView)
                && !isSubviewOf(hitView, parent: inspectorView)
            {
                hideInspector()
            }
        }

        private func isSubviewOf(_ view: NSView?, parent: NSView) -> Bool {
            var current = view
            while let currentView = current {
                if currentView == parent {
                    return true
                }
                current = currentView.superview
            }
            return false
        }

        private func showInspector() {
            guard !isInspectorVisible else { return }

            isInspectorVisible = true

            // Use saved width or default, clamped to min/max
            let savedWidth = UserDefaults.standard.float(forKey: inspectorWidthKey)
            let targetWidth =
                savedWidth > 0
                ? min(max(CGFloat(savedWidth), inspectorMinWidth), inspectorMaxWidth)
                : 250

            // Unhide and set explicit frame BEFORE animation
            inspectorView.isHidden = false
            let inspectorFrame = NSRect(
                x: splitView.bounds.width - targetWidth,
                y: 0,
                width: targetWidth,
                height: splitView.bounds.height
            )
            inspectorView.frame = inspectorFrame

            // Force layout
            inspectorView.needsLayout = true
            inspectorView.layoutSubtreeIfNeeded()

            // Calculate divider position
            let dividerPosition = splitView.bounds.width - targetWidth

            NSAnimationContext.runAnimationGroup(
                { context in
                    context.duration = 0.25
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    self.splitView.animator().setPosition(dividerPosition, ofDividerAt: 0)
                },
                completionHandler: {
                    Task { @MainActor in
                        self.updateCollectionViewLayout()
                    }
                })
        }

        private func hideInspector() {
            guard isInspectorVisible else { return }

            isInspectorVisible = false

            NSAnimationContext.runAnimationGroup(
                { context in
                    context.duration = 0.25
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    self.splitView.animator().setPosition(
                        self.splitView.bounds.width, ofDividerAt: 0)
                },
                completionHandler: {
                    Task { @MainActor in
                        self.inspectorView.isHidden = true
                        // Update collection view layout after animation
                        self.updateCollectionViewLayout()
                    }
                })

            // Deselect items
            collectionView.deselectAll(nil)
            selectedWallpaper = nil
        }

        @objc private func addWallpaper() {
            let openPanel = NSOpenPanel()
            openPanel.title = "选择壁纸视频"
            openPanel.message = "选择一个 MP4 格式的视频文件"
            openPanel.allowedContentTypes = [.mpeg4Movie, .movie]
            openPanel.allowsMultipleSelection = true
            openPanel.canChooseDirectories = false

            openPanel.begin { [weak self] response in
                guard let self = self, response == .OK else { return }

                for url in openPanel.urls {
                    let name = url.deletingPathExtension().lastPathComponent
                    let wallpaper = WallpaperItem(name: name, url: url)
                    self.wallpaperManager.addWallpaper(wallpaper)
                }

                self.collectionView.reloadData()
            }
        }

        @objc private func addFolder() {
            let openPanel = NSOpenPanel()
            openPanel.title = "选择壁纸文件夹"
            openPanel.message = "选择一个包含视频文件的文件夹"
            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles = false
            openPanel.allowsMultipleSelection = false

            openPanel.begin { [weak self] response in
                guard let self = self, response == .OK, let folderURL = openPanel.url else {
                    return
                }

                self.loadWallpapersFromFolder(folderURL)
            }
        }

        private func loadWallpapersFromFolder(_ folderURL: URL) {
            let fileManager = FileManager.default
            guard
                let enumerator = fileManager.enumerator(
                    at: folderURL, includingPropertiesForKeys: [.isRegularFileKey])
            else { return }

            let videoExtensions = ["mp4", "mov", "m4v"]
            var addedCount = 0

            for case let fileURL as URL in enumerator {
                guard videoExtensions.contains(fileURL.pathExtension.lowercased()) else { continue }

                let name = fileURL.deletingPathExtension().lastPathComponent
                let wallpaper = WallpaperItem(name: name, url: fileURL)
                wallpaperManager.addWallpaper(wallpaper)
                addedCount += 1
            }

            if addedCount > 0 {
                collectionView.reloadData()

                let alert = NSAlert()
                alert.messageText = "导入完成"
                alert.informativeText = "成功导入 \(addedCount) 个壁纸"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "确定")
                alert.runModal()
            }
        }

        @objc private func toggleEnable() {
            wallpaperEngine.isEnabled.toggle()
            // Reload toolbar to update button state
            if let window = view.window {
                window.toolbar?.validateVisibleItems()
            }
        }

        @objc private func togglePause() {
            wallpaperEngine.isPaused.toggle()
            updatePauseButton()
        }

        private func updatePauseButton() {
            let isPaused = wallpaperEngine.isPaused

            // Update title and image
            togglePauseButton.title = isPaused ? "恢复" : "暂停"
            togglePauseButton.image = NSImage(
                systemSymbolName: isPaused ? "play.fill" : "pause.fill",
                accessibilityDescription: "暂停")

            // Update tooltip with auto-pause status
            var tooltip = isPaused ? "恢复播放" : "暂停播放"
            let settings = AppSettings.load()
            if settings.pauseWhenWindowMaximized || settings.pauseWhenLowPowerMode {
                tooltip += "\n\n🔧 已启用自动暂停:"
                if settings.pauseWhenWindowMaximized {
                    tooltip += "\n  • 窗口最大化时暂停"
                }
                if settings.pauseWhenLowPowerMode {
                    tooltip += "\n  • 省电模式时暂停"
                }
            }
            togglePauseButton.toolTip = tooltip

            // Apply label visibility setting
            let showLabels = settings.showToolbarLabels
            if !showLabels {
                togglePauseButton.imagePosition = .imageOnly
                togglePauseButton.title = ""
            } else {
                togglePauseButton.imagePosition = .imageAbove
            }
        }

        @objc private func showSettings() {
            let alert = NSAlert()
            alert.messageText = "全局设置"
            alert.informativeText = "配置壁纸搜索路径"
            alert.alertStyle = .informational

            let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
            textField.placeholderString = "/Users/你的用户名/Movies/Wallpapers"
            alert.accessoryView = textField

            alert.addButton(withTitle: "添加路径")
            alert.addButton(withTitle: "取消")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let path = textField.stringValue
                if !path.isEmpty {
                    let folderURL = URL(fileURLWithPath: path)
                    loadWallpapersFromFolder(folderURL)
                }
            }
        }

        private func applyWallpaper(_ wallpaper: WallpaperItem) {
            // Don't reload if already playing the same wallpaper
            if let current = wallpaperEngine.getCurrentWallpaper(), current.id == wallpaper.id {
                print("⏭️ Wallpaper already playing: \(wallpaper.name)")
                return
            }

            wallpaperEngine.playWallpaper(wallpaper)
            wallpaperManager.updateLastPlayed(wallpaper)
            currentAppliedWallpaper = wallpaper

            // Update collection view to show current wallpaper indicator
            collectionView.reloadData()

            let notification = NSUserNotification()
            notification.title = "壁纸已应用"
            notification.informativeText = wallpaper.name
            NSUserNotificationCenter.default.deliver(notification)
        }

        private func toggleFavorite(_ wallpaper: WallpaperItem) {
            wallpaperManager.toggleFavorite(wallpaper)
            collectionView.reloadData()
        }

        private func deleteWallpaper(_ wallpaper: WallpaperItem) {
            let alert = NSAlert()
            alert.messageText = "删除壁纸"
            alert.informativeText = "确定要删除 \"\(wallpaper.name)\" 吗？"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "删除")
            alert.addButton(withTitle: "取消")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                wallpaperManager.removeWallpaper(wallpaper)

                if currentAppliedWallpaper?.id == wallpaper.id {
                    currentAppliedWallpaper = nil
                }

                if selectedWallpaper?.id == wallpaper.id {
                    selectedWallpaper = nil
                    hideInspector()
                }

                collectionView.reloadData()
            }
        }
    }

    // MARK: - NSToolbarDelegate
    extension MainViewController: NSToolbarDelegate {
        func toolbar(
            _ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
            willBeInsertedIntoToolbar flag: Bool
        ) -> NSToolbarItem? {

            switch itemIdentifier {
            case .addWallpaper:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.label = "添加壁纸"
                item.paletteLabel = "添加壁纸"
                item.toolTip = "手动添加 MP4 壁纸文件"
                item.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "添加")
                item.target = self
                item.action = #selector(addWallpaper)
                return item

            case .addFolder:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.label = "添加文件夹"
                item.paletteLabel = "添加文件夹"
                item.toolTip = "从文件夹批量导入壁纸"
                item.image = NSImage(
                    systemSymbolName: "folder.badge.plus", accessibilityDescription: "文件夹")
                item.target = self
                item.action = #selector(addFolder)
                return item

            case .toggleEnable:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.label = wallpaperEngine.isEnabled ? "禁用" : "启用"
                item.paletteLabel = "启用/禁用"
                item.toolTip = wallpaperEngine.isEnabled ? "禁用壁纸" : "启用壁纸"
                item.image = NSImage(
                    systemSymbolName: wallpaperEngine.isEnabled ? "stop.circle" : "play.circle",
                    accessibilityDescription: "启用")
                item.target = self
                item.action = #selector(toggleEnable)
                return item

            case .togglePause:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.paletteLabel = "暂停/恢复"

                // Create custom button for dynamic updates
                togglePauseButton = NSButton()
                togglePauseButton.bezelStyle = .texturedRounded
                togglePauseButton.isBordered = false
                togglePauseButton.target = self
                togglePauseButton.action = #selector(togglePause)
                togglePauseButton.imagePosition = .imageAbove
                togglePauseButton.setButtonType(.momentaryChange)

                // Set initial state
                let isPaused = wallpaperEngine.isPaused
                togglePauseButton.title = isPaused ? "恢复" : "暂停"

                // Build tooltip with auto-pause status
                var tooltip = isPaused ? "恢复播放" : "暂停播放"
                let settings = AppSettings.load()
                if settings.pauseWhenWindowMaximized || settings.pauseWhenLowPowerMode {
                    tooltip += "\n\n🔧 已启用自动暂停:"
                    if settings.pauseWhenWindowMaximized {
                        tooltip += "\n  • 窗口最大化时暂停"
                    }
                    if settings.pauseWhenLowPowerMode {
                        tooltip += "\n  • 省电模式时暂停"
                    }
                }
                togglePauseButton.toolTip = tooltip

                togglePauseButton.image = NSImage(
                    systemSymbolName: isPaused ? "play.fill" : "pause.fill",
                    accessibilityDescription: "暂停")

                // Load display mode from settings
                if !settings.showToolbarLabels {
                    togglePauseButton.imagePosition = .imageOnly
                    togglePauseButton.title = ""
                }

                item.view = togglePauseButton
                item.isEnabled = wallpaperEngine.isEnabled
                return item

            case .settings:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.label = "全局设置"
                item.paletteLabel = "全局设置"
                item.toolTip = "配置壁纸搜索路径"
                item.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "设置")
                item.target = self
                item.action = #selector(showSettings)
                return item

            default:
                return nil
            }
        }

        func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            return [
                .addWallpaper,
                .addFolder,
                .flexibleSpace,
                .toggleEnable,
                .togglePause,
                .space,
                .settings,
            ]
        }

        func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            return [
                .addWallpaper,
                .addFolder,
                .toggleEnable,
                .togglePause,
                .settings,
                .space,
                .flexibleSpace,
                .addFolder,
                .settings,
                .flexibleSpace,
                .space,
            ]
        }
    }

    // MARK: - NSCollectionViewDataSource
    extension MainViewController: NSCollectionViewDataSource {
        func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int)
            -> Int
        {
            return wallpaperManager.wallpapers.count
        }

        func collectionView(
            _ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath
        ) -> NSCollectionViewItem {
            let item =
                collectionView.makeItem(
                    withIdentifier: WallpaperCollectionViewItem.identifier,
                    for: indexPath
                ) as! WallpaperCollectionViewItem

            let wallpaper = wallpaperManager.wallpapers[indexPath.item]
            let isCurrentlyApplied = (currentAppliedWallpaper?.id == wallpaper.id)
            item.configure(with: wallpaper, isCurrentlyApplied: isCurrentlyApplied)
            item.delegate = self

            return item
        }
    }

    // MARK: - NSCollectionViewDelegate
    extension MainViewController: NSCollectionViewDelegate {
        func collectionView(
            _ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>
        ) {
            guard let indexPath = indexPaths.first else { return }
            let wallpaper = wallpaperManager.wallpapers[indexPath.item]

            // Single click - show inspector
            selectedWallpaper = wallpaper
            inspectorView.configure(with: wallpaper)
            inspectorView.updateEngineState(
                quality: wallpaperEngine.quality,
                contentMode: wallpaperEngine.contentMode
            )
            showInspector()
        }

        func collectionView(
            _ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>
        ) {
            // Don't hide inspector on deselect - only on background click
        }
    }

    // MARK: - WallpaperCollectionViewItemDelegate
    extension MainViewController: WallpaperCollectionViewItemDelegate {
        func wallpaperItemDidDoubleClick(
            _ item: WallpaperCollectionViewItem, wallpaper: WallpaperItem
        ) {
            applyWallpaper(wallpaper)
        }

        func wallpaperItemDidRightClick(
            _ item: WallpaperCollectionViewItem, wallpaper: WallpaperItem, event: NSEvent
        ) {
            let menu = NSMenu()

            let applyItem = NSMenuItem(
                title: "应用壁纸", action: #selector(contextMenuApply(_:)), keyEquivalent: "")
            applyItem.target = self
            applyItem.representedObject = wallpaper
            menu.addItem(applyItem)

            menu.addItem(NSMenuItem.separator())

            // Favorite toggle
            let isFavorite =
                wallpaperManager.wallpapers.first(where: { $0.id == wallpaper.id })?.isFavorite
                ?? false
            let favoriteItem = NSMenuItem(
                title: isFavorite ? "取消喜欢" : "添加到喜欢",
                action: #selector(contextMenuToggleFavorite(_:)),
                keyEquivalent: ""
            )
            favoriteItem.target = self
            favoriteItem.representedObject = wallpaper
            menu.addItem(favoriteItem)

            menu.addItem(NSMenuItem.separator())

            let deleteItem = NSMenuItem(
                title: "删除壁纸", action: #selector(contextMenuDelete(_:)), keyEquivalent: "")
            deleteItem.target = self
            deleteItem.representedObject = wallpaper
            menu.addItem(deleteItem)

            NSMenu.popUpContextMenu(menu, with: event, for: item.view)
        }

        @objc private func contextMenuApply(_ sender: NSMenuItem) {
            guard let wallpaper = sender.representedObject as? WallpaperItem else { return }
            applyWallpaper(wallpaper)
        }

        @objc private func contextMenuToggleFavorite(_ sender: NSMenuItem) {
            guard let wallpaper = sender.representedObject as? WallpaperItem else { return }
            toggleFavorite(wallpaper)
        }

        @objc private func contextMenuDelete(_ sender: NSMenuItem) {
            guard let wallpaper = sender.representedObject as? WallpaperItem else { return }
            deleteWallpaper(wallpaper)
        }
    }

    // MARK: - InspectorViewDelegate
    extension MainViewController: InspectorViewDelegate {
        func inspectorDidRequestApply(_ wallpaper: WallpaperItem) {
            applyWallpaper(wallpaper)
        }

        func inspectorDidChangeMute(_ wallpaper: WallpaperItem, muted: Bool) {
            // Update wallpaper mute state
            wallpaperManager.updateWallpaperMute(wallpaper, muted: muted)

            // If this is the current wallpaper, update volume without reloading
            if let updatedWallpaper = wallpaperManager.wallpapers.first(where: {
                $0.id == wallpaper.id
            }) {
                wallpaperEngine.updateCurrentWallpaperMute(updatedWallpaper)
            }
        }

        func inspectorDidChangeQuality(_ quality: VideoQuality) {
            wallpaperEngine.quality = quality
        }

        func inspectorDidChangeContentMode(_ contentMode: ContentMode) {
            wallpaperEngine.contentMode = contentMode
        }
    }

    // MARK: - Toolbar Item Identifiers
    extension MainViewController: NSSplitViewDelegate {
        func splitView(
            _ splitView: NSSplitView,
            canCollapseSubview subview: NSView
        ) -> Bool {
            // Allow collapsing inspector only
            return subview == inspectorView
        }

        func splitView(
            _ splitView: NSSplitView,
            shouldAdjustSizeOfSubview subview: NSView
        ) -> Bool {
            // Inspector should not auto-adjust, only collection view adjusts
            return subview == scrollView
        }

        func splitView(
            _ splitView: NSSplitView,
            constrainMinCoordinate proposedMinimumPosition: CGFloat,
            ofSubviewAt dividerIndex: Int
        ) -> CGFloat {
            // Allow dragging but limit inspector max width
            return splitView.bounds.width - inspectorMaxWidth
        }

        func splitView(
            _ splitView: NSSplitView,
            constrainMaxCoordinate proposedMaximumPosition: CGFloat,
            ofSubviewAt dividerIndex: Int
        ) -> CGFloat {
            // Allow dragging but limit inspector min width
            return splitView.bounds.width - inspectorMinWidth
        }

        func splitViewDidResizeSubviews(_ notification: Notification) {
            // Update collection view layout when split view is resized
            updateCollectionViewLayout()

            // Save inspector width if visible
            if isInspectorVisible && !inspectorView.isHidden {
                let inspectorWidth = inspectorView.frame.width
                UserDefaults.standard.set(Float(inspectorWidth), forKey: inspectorWidthKey)
            }
        }
    }

    extension NSToolbarItem.Identifier {
        static let addWallpaper = NSToolbarItem.Identifier("addWallpaper")
        static let addFolder = NSToolbarItem.Identifier("addFolder")
        static let toggleEnable = NSToolbarItem.Identifier("toggleEnable")
        static let togglePause = NSToolbarItem.Identifier("togglePause")
        static let settings = NSToolbarItem.Identifier("settings")
    }
#endif
