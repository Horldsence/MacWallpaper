import Foundation

#if os(macOS)
    import AppKit
    import AVFoundation

    // Video quality settings
    enum VideoQuality: String, CaseIterable {
        case low = "低"
        case medium = "中"
        case high = "高"
        case original = "原始"

        var description: String {
            return self.rawValue
        }
    }

    // Content mode for video display
    enum ContentMode: String, CaseIterable {
        case fill = "填充"  // resizeAspectFill - 保持比例，裁剪
        case fit = "适应"  // resizeAspect - 保持比例，黑边
        case stretch = "拉伸"  // resize - 不保持比例

        var description: String {
            return self.rawValue
        }

        var videoGravity: AVLayerVideoGravity {
            switch self {
            case .fill: return .resizeAspectFill
            case .fit: return .resizeAspect
            case .stretch: return .resize
            }
        }
    }

    @MainActor
    class WallpaperEngine {
        private var wallpaperWindows: [WallpaperWindow] = []
        private var currentWallpaper: WallpaperItem?
        private var isWindowsCreated: Bool = false

        private let userDefaults = UserDefaults.standard
        private let lastWallpaperKey = "LastPlayedWallpaper"

        // Auto-pause state tracking
        private var isPausedByWindowMaximize = false
        private var isPausedByLowPowerMode = false
        private var manualPauseState = false

        // Settings
        var appSettings: AppSettings = AppSettings.load() {
            didSet {
                updateAutoPauseObservers()
            }
        }

        // State machine: disabled -> enabled -> paused
        enum PlaybackState {
            case disabled  // Windows destroyed
            case enabled  // Windows active, video playing
            case paused  // Windows active, video stopped
        }

        private var playbackState: PlaybackState = .disabled {
            didSet {
                applyPlaybackState()
            }
        }

        // Public interface
        var isEnabled: Bool {
            get { playbackState != .disabled }
            set {
                if newValue {
                    if playbackState == .disabled {
                        playbackState = .enabled
                    }
                } else {
                    playbackState = .disabled
                }
            }
        }

        var isPaused: Bool {
            get { playbackState == .paused }
            set {
                guard playbackState != .disabled else { return }
                manualPauseState = newValue
                updatePauseState()
            }
        }

        var globalMuted: Bool = false {
            didSet {
                updateVolume()
            }
        }

        var quality: VideoQuality = .high {
            didSet {
                updateQuality()
            }
        }

        var contentMode: ContentMode = .fill {
            didSet {
                updateContentMode()
            }
        }

        init() {
            // Load last enabled state
            let wasEnabled = userDefaults.bool(forKey: "WallpaperEnabled")
            if wasEnabled {
                playbackState = .enabled
            }

            // Don't create windows immediately - wait until enabled
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(screenConfigurationChanged),
                name: NSApplication.didChangeScreenParametersNotification,
                object: nil
            )

            // Setup auto-pause observers
            updateAutoPauseObservers()
        }

        private func setupWallpaperWindows() {
            guard !isWindowsCreated else { return }

            // Create wallpaper window for each screen
            for screen in NSScreen.screens {
                let wallpaperWindow = WallpaperWindow(screen: screen)
                wallpaperWindows.append(wallpaperWindow)
            }

            isWindowsCreated = true
            print("🪟 Wallpaper windows created: \(wallpaperWindows.count)")
        }

        private func destroyWallpaperWindows() {
            // Assume videos are already stopped by caller
            // Just destroy windows asynchronously
            let windowsToClose = wallpaperWindows
            wallpaperWindows.removeAll()
            isWindowsCreated = false

            // Close windows on next runloop to ensure CA is done
            DispatchQueue.main.async {
                windowsToClose.forEach { $0.close() }
                print("🗑️ Wallpaper windows destroyed")
            }
        }

        @objc private func screenConfigurationChanged() {
            // Only recreate if wallpaper is not disabled
            guard playbackState != .disabled else { return }

            let currentState = playbackState

            // Stop videos first
            for window in wallpaperWindows {
                window.stopVideo()
            }

            // Recreate wallpaper windows for new screen configuration
            destroyWallpaperWindows()

            // Wait for window destruction before recreating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                self.setupWallpaperWindows()

                // Reapply based on state
                if let wallpaper = self.currentWallpaper {
                    if currentState == .enabled {
                        self.applyWallpaperToWindows(wallpaper)
                    }
                    // If paused, windows exist but no video playing
                }
            }
        }

        private func applyPlaybackState() {
            switch playbackState {
            case .disabled:
                // Stop videos first, then destroy windows asynchronously
                for window in wallpaperWindows {
                    window.stopVideo()
                }

                // Schedule window destruction on next runloop to avoid CA crashes
                DispatchQueue.main.async { [weak self] in
                    self?.destroyWallpaperWindows()
                }
                userDefaults.set(false, forKey: "WallpaperEnabled")

            case .enabled:
                // Create windows if needed
                if !isWindowsCreated {
                    setupWallpaperWindows()
                    // Try to restore last wallpaper
                    if currentWallpaper == nil {
                        currentWallpaper = loadLastWallpaper()
                    }
                }

                // Play or resume video
                if let wallpaper = currentWallpaper {
                    // Always reload to ensure quality/settings are applied
                    applyWallpaperToWindows(wallpaper)
                }
                userDefaults.set(true, forKey: "WallpaperEnabled")

            case .paused:
                // Keep windows, pause video (preserve frame)
                for window in wallpaperWindows {
                    window.pauseVideo()
                }
                userDefaults.set(true, forKey: "WallpaperEnabled")
            }
        }

        func playWallpaper(_ wallpaper: WallpaperItem) {
            // Don't reload if already playing the same wallpaper
            if let current = currentWallpaper, current.id == wallpaper.id {
                print("⏭️ Skipping reload - already playing: \(wallpaper.name)")
                return
            }

            print("🎬 Playing wallpaper: \(wallpaper.name)")
            currentWallpaper = wallpaper
            saveLastWallpaper(wallpaper)

            // Auto-enable if disabled
            if playbackState == .disabled {
                playbackState = .enabled
            } else {
                // Already enabled or paused, just play
                playbackState = .enabled
            }
        }

        private func applyWallpaperToWindows(_ wallpaper: WallpaperItem) {
            let effectiveMuted = globalMuted || wallpaper.isMuted
            for window in wallpaperWindows {
                window.loadVideo(
                    url: wallpaper.url, muted: effectiveMuted, quality: quality,
                    contentMode: contentMode)
            }
        }

        func pause() {
            guard playbackState == .enabled else { return }
            playbackState = .paused
        }

        func resume() {
            guard playbackState == .paused else { return }
            playbackState = .enabled
        }

        func stop() {
            currentWallpaper = nil
            for window in wallpaperWindows {
                window.stopVideo()
            }
        }

        func getCurrentWallpaper() -> WallpaperItem? {
            return currentWallpaper
        }

        func getLastWallpaper() -> WallpaperItem? {
            return loadLastWallpaper()
        }

        func updateCurrentWallpaperMute(_ updatedWallpaper: WallpaperItem) {
            // Update current wallpaper reference without reloading video
            if currentWallpaper?.id == updatedWallpaper.id {
                currentWallpaper = updatedWallpaper
                updateVolume()
            }
        }

        private func updateVolume() {
            guard let wallpaper = currentWallpaper else { return }
            let effectiveMuted = globalMuted || wallpaper.isMuted
            for window in wallpaperWindows {
                window.setMuted(effectiveMuted)
            }
        }

        private func updateQuality() {
            // Reload video with new quality if wallpaper is playing
            if let wallpaper = currentWallpaper, playbackState == .enabled {
                applyWallpaperToWindows(wallpaper)
            }
        }

        private func updateContentMode() {
            // Update content mode for all windows
            for window in wallpaperWindows {
                window.setContentMode(contentMode)
            }
        }

        // MARK: - Persistence

        private func saveLastWallpaper(_ wallpaper: WallpaperItem) {
            if let data = try? JSONEncoder().encode(wallpaper) {
                userDefaults.set(data, forKey: lastWallpaperKey)
            }
        }

        private func loadLastWallpaper() -> WallpaperItem? {
            guard let data = userDefaults.data(forKey: lastWallpaperKey),
                let wallpaper = try? JSONDecoder().decode(WallpaperItem.self, from: data)
            else {
                return nil
            }
            return wallpaper
        }

        // MARK: - Auto-pause functionality

        private func updateAutoPauseObservers() {
            // Window maximize observer
            if appSettings.pauseWhenWindowMaximized {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(windowDidBecomeKey),
                    name: NSWindow.didBecomeKeyNotification,
                    object: nil
                )
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(windowDidResignKey),
                    name: NSWindow.didResignKeyNotification,
                    object: nil
                )
            } else {
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSWindow.didBecomeKeyNotification,
                    object: nil
                )
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSWindow.didResignKeyNotification,
                    object: nil
                )
                isPausedByWindowMaximize = false
            }

            // Low power mode observer (macOS 12+)
            if appSettings.pauseWhenLowPowerMode {
                if #available(macOS 12.0, *) {
                    NotificationCenter.default.addObserver(
                        self,
                        selector: #selector(powerStateChanged),
                        name: Notification.Name.NSProcessInfoPowerStateDidChange,
                        object: nil
                    )
                    checkLowPowerMode()
                }
            } else {
                if #available(macOS 12.0, *) {
                    NotificationCenter.default.removeObserver(
                        self,
                        name: Notification.Name.NSProcessInfoPowerStateDidChange,
                        object: nil
                    )
                }
                isPausedByLowPowerMode = false
            }

            updatePauseState()
        }

        @objc private func windowDidBecomeKey(_ notification: Notification) {
            guard appSettings.pauseWhenWindowMaximized else { return }

            if let window = notification.object as? NSWindow {
                // Check if any non-wallpaper window is maximized
                if window.isZoomed && !wallpaperWindows.contains(where: { $0 == window }) {
                    isPausedByWindowMaximize = true
                    updatePauseState()
                }
            }
        }

        @objc private func windowDidResignKey(_ notification: Notification) {
            guard appSettings.pauseWhenWindowMaximized else { return }

            // Check if any window is still maximized and key
            let hasMaximizedWindow = NSApp.windows.contains { window in
                window.isZoomed && window.isKeyWindow
                    && !wallpaperWindows.contains(where: { $0 == window })
            }

            if !hasMaximizedWindow {
                isPausedByWindowMaximize = false
                updatePauseState()
            }
        }

        @objc private func powerStateChanged() {
            guard appSettings.pauseWhenLowPowerMode else { return }
            checkLowPowerMode()
        }

        private func checkLowPowerMode() {
            guard appSettings.pauseWhenLowPowerMode else { return }

            if #available(macOS 12.0, *) {
                let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
                if isLowPowerMode != isPausedByLowPowerMode {
                    isPausedByLowPowerMode = isLowPowerMode
                    updatePauseState()
                }
            }
        }

        private func updatePauseState() {
            guard playbackState != .disabled else { return }

            let shouldPause = manualPauseState || isPausedByWindowMaximize || isPausedByLowPowerMode
            playbackState = shouldPause ? .paused : .enabled
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }

    struct WallpaperItem: Codable, Identifiable, Equatable {
        let id: UUID
        let name: String
        let url: URL
        let thumbnailPath: String?
        let dateAdded: Date
        var isFavorite: Bool
        var lastPlayedDate: Date?
        var isMuted: Bool  // Per-wallpaper mute setting

        init(
            name: String, url: URL, thumbnailPath: String? = nil, isFavorite: Bool = false,
            isMuted: Bool = false
        ) {
            self.id = UUID()
            self.name = name
            self.url = url
            self.thumbnailPath = thumbnailPath
            self.dateAdded = Date()
            self.isFavorite = isFavorite
            self.lastPlayedDate = nil
            self.isMuted = isMuted
        }

        static func == (lhs: WallpaperItem, rhs: WallpaperItem) -> Bool {
            return lhs.id == rhs.id
        }
    }
#endif
