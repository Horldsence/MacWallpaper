import Foundation

#if os(macOS)
import AppKit

class MainViewController: NSViewController {
    private var wallpaperEngine: WallpaperEngine
    private var wallpaperManager: WallpaperManager
    
    // UI Components
    private var toolbar: NSToolbar!
    private var collectionView: NSCollectionView!
    private var scrollView: NSScrollView!
    private var settingsPanel: SettingsPanel?
    
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
        setupCollectionView()
    }
    
    private func setupToolbar() {
        toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        
        if let window = view.window {
            window.toolbar = toolbar
            window.titleVisibility = .hidden
        } else {
            // Defer toolbar setup until window is available
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let window = self.view.window else { return }
                window.toolbar = self.toolbar
                window.titleVisibility = .hidden
            }
        }
    }
    
    private func setupCollectionView() {
        // Setup flow layout
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 200, height: 180)
        flowLayout.sectionInset = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        flowLayout.minimumInteritemSpacing = 20
        flowLayout.minimumLineSpacing = 20
        
        // Setup collection view
        collectionView = NSCollectionView()
        collectionView.collectionViewLayout = flowLayout
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isSelectable = true
        collectionView.backgroundColors = [.clear]
        
        // Register cell
        collectionView.register(
            WallpaperCollectionViewItem.self,
            forItemWithIdentifier: WallpaperCollectionViewItem.identifier
        )
        
        // Setup scroll view
        scrollView = NSScrollView(frame: view.bounds)
        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        
        view.addSubview(scrollView)
        
        // Load wallpapers
        wallpaperManager.loadWallpapers()
        collectionView.reloadData()
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
    
    @objc private func searchWallpapers() {
        let alert = NSAlert()
        alert.messageText = "壁纸搜索"
        alert.informativeText = "请输入壁纸搜索地址或关键词："
        alert.alertStyle = .informational
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.placeholderString = "https://example.com 或 搜索关键词"
        alert.accessoryView = textField
        
        alert.addButton(withTitle: "打开")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let input = textField.stringValue
            if let url = URL(string: input), url.scheme != nil {
                NSWorkspace.shared.open(url)
            } else {
                // Search online (could integrate with wallpaper websites)
                if let encodedQuery = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let searchURL = URL(string: "https://www.google.com/search?q=\(encodedQuery)+wallpaper+mp4") {
                    NSWorkspace.shared.open(searchURL)
                }
            }
        }
    }
    
    @objc private func showSettings() {
        if settingsPanel == nil {
            settingsPanel = SettingsPanel(wallpaperEngine: wallpaperEngine)
        }
        settingsPanel?.showWindow(nil)
    }
}

// MARK: - NSToolbarDelegate
extension MainViewController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
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
            
        case .searchWallpaper:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "搜索壁纸"
            item.paletteLabel = "搜索壁纸"
            item.toolTip = "搜索在线壁纸资源"
            item.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "搜索")
            item.target = self
            item.action = #selector(searchWallpapers)
            return item
            
        case .settings:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "设置"
            item.paletteLabel = "设置"
            item.toolTip = "显示质量、静音等设置"
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
            .searchWallpaper,
            .flexibleSpace,
            .settings
        ]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .addWallpaper,
            .searchWallpaper,
            .settings,
            .flexibleSpace,
            .space
        ]
    }
}

// MARK: - NSCollectionViewDataSource
extension MainViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return wallpaperManager.wallpapers.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(
            withIdentifier: WallpaperCollectionViewItem.identifier,
            for: indexPath
        ) as! WallpaperCollectionViewItem
        
        let wallpaper = wallpaperManager.wallpapers[indexPath.item]
        item.configure(with: wallpaper)
        
        return item
    }
}

// MARK: - NSCollectionViewDelegate
extension MainViewController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else { return }
        let wallpaper = wallpaperManager.wallpapers[indexPath.item]
        
        // Play selected wallpaper
        wallpaperEngine.playWallpaper(wallpaper)
        
        // Show notification
        let notification = NSUserNotification()
        notification.title = "壁纸已应用"
        notification.informativeText = wallpaper.name
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// MARK: - Toolbar Item Identifiers
extension NSToolbarItem.Identifier {
    static let addWallpaper = NSToolbarItem.Identifier("AddWallpaper")
    static let searchWallpaper = NSToolbarItem.Identifier("SearchWallpaper")
    static let settings = NSToolbarItem.Identifier("Settings")
}
#endif
