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
                let savedWallpapers = try? JSONDecoder().decode([WallpaperItem].self, from: data)
            {
                wallpapers = savedWallpapers
                sortWallpapers()
            }
        }

        func addWallpaper(_ wallpaper: WallpaperItem) {
            wallpapers.append(wallpaper)
            sortWallpapers()
            saveWallpapers()
        }

        func removeWallpaper(at index: Int) {
            guard index < wallpapers.count else { return }
            wallpapers.remove(at: index)
            saveWallpapers()
        }

        func removeWallpaper(_ wallpaper: WallpaperItem) {
            wallpapers.removeAll { $0.id == wallpaper.id }
            saveWallpapers()
        }

        func toggleFavorite(_ wallpaper: WallpaperItem) {
            if let index = wallpapers.firstIndex(where: { $0.id == wallpaper.id }) {
                wallpapers[index].isFavorite.toggle()
                sortWallpapers()
                saveWallpapers()
            }
        }

        func updateLastPlayed(_ wallpaper: WallpaperItem) {
            if let index = wallpapers.firstIndex(where: { $0.id == wallpaper.id }) {
                wallpapers[index].lastPlayedDate = Date()
                sortWallpapers()
                saveWallpapers()
            }
        }

        func getFavorites() -> [WallpaperItem] {
            return wallpapers.filter { $0.isFavorite }
        }

        func getRecentlyPlayed() -> [WallpaperItem] {
            return
                wallpapers
                .filter { $0.lastPlayedDate != nil }
                .sorted {
                    ($0.lastPlayedDate ?? .distantPast) > ($1.lastPlayedDate ?? .distantPast)
                }
        }

        func getFirstWallpaper() -> WallpaperItem? {
            // Priority: Favorites > Recently Played > First
            if let favorite = getFavorites().first {
                return favorite
            }
            if let recent = getRecentlyPlayed().first {
                return recent
            }
            return wallpapers.first
        }

        func updateWallpaperMute(_ wallpaper: WallpaperItem, muted: Bool) {
            if let index = wallpapers.firstIndex(where: { $0.id == wallpaper.id }) {
                wallpapers[index].isMuted = muted
                saveWallpapers()
            }
        }

        private func sortWallpapers() {
            wallpapers.sort { lhs, rhs in
                // 1. Favorites first
                if lhs.isFavorite != rhs.isFavorite {
                    return lhs.isFavorite
                }

                // 2. Recently played next
                let lhsLastPlayed = lhs.lastPlayedDate ?? .distantPast
                let rhsLastPlayed = rhs.lastPlayedDate ?? .distantPast

                if lhsLastPlayed != rhsLastPlayed {
                    return lhsLastPlayed > rhsLastPlayed
                }

                // 3. Date added (newest first)
                return lhs.dateAdded > rhs.dateAdded
            }
        }

        func saveWallpapers() {
            if let data = try? JSONEncoder().encode(wallpapers) {
                userDefaults.set(data, forKey: wallpapersKey)
            }
        }
    }
#endif
