import Foundation

#if os(macOS)
    import AppKit

    /// Global application settings manager
    struct AppSettings: Codable {
        // Smart pause: when enabled, other auto-pause options are forced on and locked
        var smartPause: Bool = false
        // UI Settings
        var showToolbarLabels: Bool = false

        // Auto-pause Settings
        // Defaults set to true so that when smartPause is disabled they remain enabled
        var pauseWhenWindowMaximized: Bool = true
        var pauseWhenLowPowerMode: Bool = true

        // UserDefaults key
        private static let settingsKey = "AppSettings"

        /// Save settings to UserDefaults
        func save() {
            if let data = try? JSONEncoder().encode(self) {
                UserDefaults.standard.set(data, forKey: Self.settingsKey)
            }
        }

        /// Load settings from UserDefaults
        static func load() -> AppSettings {
            guard let data = UserDefaults.standard.data(forKey: settingsKey),
                let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
            else {
                return AppSettings()
            }
            return settings
        }

        /// Reset to default settings
        static func reset() -> AppSettings {
            let settings = AppSettings()
            settings.save()
            return settings
        }
    }
#endif
