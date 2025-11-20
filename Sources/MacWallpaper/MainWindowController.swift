import Foundation

#if os(macOS)
import AppKit

class MainWindowController: NSWindowController {
    private var wallpaperEngine: WallpaperEngine
    private var wallpaperManager: WallpaperManager
    private var mainViewController: MainViewController?
    
    init(wallpaperEngine: WallpaperEngine) {
        self.wallpaperEngine = wallpaperEngine
        self.wallpaperManager = WallpaperManager()
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        window.title = "MacWallpaper"
        window.center()
        window.minSize = NSSize(width: 700, height: 500)
        
        // Set window delegate to handle window events
        window.delegate = self
        
        setupViewController()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViewController() {
        mainViewController = MainViewController(
            wallpaperEngine: wallpaperEngine,
            wallpaperManager: wallpaperManager
        )
        window?.contentViewController = mainViewController
    }
}

extension MainWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Don't terminate app when window closes
    }
}
#endif
