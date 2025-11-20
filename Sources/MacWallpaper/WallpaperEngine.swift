import Foundation

#if os(macOS)
import AppKit
import AVFoundation

class WallpaperEngine {
    private var wallpaperWindows: [WallpaperWindow] = []
    private var currentWallpaper: WallpaperItem?
    
    // Settings
    var isMuted: Bool = false {
        didSet {
            updateVolume()
        }
    }
    
    var quality: VideoQuality = .high {
        didSet {
            updateQuality()
        }
    }
    
    enum VideoQuality: String, CaseIterable {
        case low = "低"
        case medium = "中"
        case high = "高"
        case original = "原始"
        
        var description: String {
            return self.rawValue
        }
    }
    
    init() {
        setupWallpaperWindows()
    }
    
    private func setupWallpaperWindows() {
        // Create wallpaper window for each screen
        for screen in NSScreen.screens {
            let wallpaperWindow = WallpaperWindow(screen: screen)
            wallpaperWindows.append(wallpaperWindow)
        }
        
        // Listen for screen configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func screenConfigurationChanged() {
        // Recreate wallpaper windows for new screen configuration
        wallpaperWindows.forEach { $0.close() }
        wallpaperWindows.removeAll()
        setupWallpaperWindows()
        
        // Reapply current wallpaper if exists
        if let wallpaper = currentWallpaper {
            playWallpaper(wallpaper)
        }
    }
    
    func playWallpaper(_ wallpaper: WallpaperItem) {
        currentWallpaper = wallpaper
        
        for window in wallpaperWindows {
            window.loadVideo(url: wallpaper.url, muted: isMuted, quality: quality)
        }
    }
    
    func stop() {
        currentWallpaper = nil
        for window in wallpaperWindows {
            window.stopVideo()
        }
    }
    
    private func updateVolume() {
        for window in wallpaperWindows {
            window.setMuted(isMuted)
        }
    }
    
    private func updateQuality() {
        // Reload video with new quality if wallpaper is playing
        if let wallpaper = currentWallpaper {
            playWallpaper(wallpaper)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

struct WallpaperItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let url: URL
    let thumbnailPath: String?
    let dateAdded: Date
    
    init(name: String, url: URL, thumbnailPath: String? = nil) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.thumbnailPath = thumbnailPath
        self.dateAdded = Date()
    }
}
#endif
