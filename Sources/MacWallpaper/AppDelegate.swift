import Foundation

#if os(macOS)
    import AppKit

    @MainActor
    class AppDelegate: NSObject, NSApplicationDelegate {
        var mainWindowController: MainWindowController?
        var statusBarController: StatusBarController?
        var wallpaperEngine: WallpaperEngine?

        func applicationDidFinishLaunching(_ notification: Notification) {
            // Create wallpaper engine
            wallpaperEngine = WallpaperEngine()

            // Create status bar controller
            statusBarController = StatusBarController(wallpaperEngine: wallpaperEngine!)

            // Create main window controller
            mainWindowController = MainWindowController(wallpaperEngine: wallpaperEngine!)
            mainWindowController?.showWindow(nil)

            // Configure dock icon behavior
            configureDockIcon()
        }

        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return false  // Keep app running even when main window is closed
        }

        func applicationWillTerminate(_ notification: Notification) {
            wallpaperEngine?.stop()
        }

        private func configureDockIcon() {
            // Option to hide dock icon can be configured by user
            // For now, keep it visible
            NSApp.setActivationPolicy(.regular)
        }

        func hideDockIcon() {
            NSApp.setActivationPolicy(.accessory)
        }

        func showDockIcon() {
            NSApp.setActivationPolicy(.regular)
        }
    }
#endif
