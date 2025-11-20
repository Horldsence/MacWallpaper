import Foundation

#if os(macOS)
import AppKit

class WallpaperManager {
    private(set) var wallpapers: [WallpaperItem] = []
    private let userDefaults = UserDefaults.standard
    private let wallpapersKey = "SavedWallpapers"
    
    init() {
        loadWallpapers()
    }
    
    func loadWallpapers() {
        if let data = userDefaults.data(forKey: wallpapersKey),
           let savedWallpapers = try? JSONDecoder().decode([WallpaperItem].self, from: data) {
            wallpapers = savedWallpapers
        }
    }
    
    func addWallpaper(_ wallpaper: WallpaperItem) {
        wallpapers.append(wallpaper)
        saveWallpapers()
    }
    
    func removeWallpaper(at index: Int) {
        guard index < wallpapers.count else { return }
        wallpapers.remove(at: index)
        saveWallpapers()
    }
    
    private func saveWallpapers() {
        if let data = try? JSONEncoder().encode(wallpapers) {
            userDefaults.set(data, forKey: wallpapersKey)
        }
    }
}
#endif
