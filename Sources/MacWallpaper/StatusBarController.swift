import Foundation

#if os(macOS)
    import AppKit

    @MainActor
    class StatusBarController {
        private var statusItem: NSStatusItem?
        private var wallpaperEngine: WallpaperEngine

        init(wallpaperEngine: WallpaperEngine) {
            self.wallpaperEngine = wallpaperEngine
            setupStatusBar()
        }

        private func setupStatusBar() {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

            if let button = statusItem?.button {
                button.image = createMenuIcon()
                button.image?.isTemplate = true
            }

            let menu = NSMenu()

            // Open Main Window
            menu.addItem(
                withTitle: "打开主窗口",
                action: #selector(openMainWindow),
                keyEquivalent: ""
            ).target = self

            menu.addItem(NSMenuItem.separator())

            // Enable/Disable Wallpaper
            let enableItem = NSMenuItem(
                title: wallpaperEngine.isEnabled ? "停用壁纸" : "启用壁纸",
                action: #selector(toggleEnable),
                keyEquivalent: ""
            )
            enableItem.target = self
            menu.addItem(enableItem)

            // Mute/Unmute
            let muteItem = NSMenuItem(
                title: "静音",
                action: #selector(toggleMute),
                keyEquivalent: ""
            )
            muteItem.target = self
            muteItem.state = wallpaperEngine.globalMuted ? .on : .off
            menu.addItem(muteItem)

            menu.addItem(NSMenuItem.separator())

            // Hide/Show Dock Icon
            menu.addItem(
                withTitle: "隐藏 Dock 图标",
                action: #selector(toggleDockIcon),
                keyEquivalent: ""
            ).target = self

            menu.addItem(NSMenuItem.separator())

            // About
            menu.addItem(
                withTitle: "关于 MacWallpaper",
                action: #selector(showAbout),
                keyEquivalent: ""
            ).target = self

            // Quit
            menu.addItem(
                withTitle: "退出",
                action: #selector(quit),
                keyEquivalent: "q"
            ).target = self

            statusItem?.menu = menu
        }

        private func createMenuIcon() -> NSImage {
            // Create a simple icon
            let image = NSImage(size: NSSize(width: 18, height: 18))
            image.lockFocus()

            let path = NSBezierPath(
                roundedRect: NSRect(x: 3, y: 3, width: 12, height: 12), xRadius: 2, yRadius: 2)
            NSColor.white.setFill()
            path.fill()

            image.unlockFocus()
            return image
        }

        @objc private func openMainWindow() {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.mainWindowController?.showWindow(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }

        @objc private func toggleEnable() {
            wallpaperEngine.isEnabled.toggle()

            // Update menu item title
            if let menu = statusItem?.menu,
                let enableItem = menu.items.first(where: {
                    $0.title == "启用壁纸" || $0.title == "停用壁纸"
                })
            {
                enableItem.title = wallpaperEngine.isEnabled ? "停用壁纸" : "启用壁纸"
            }
        }

        @objc private func toggleMute() {
            wallpaperEngine.globalMuted.toggle()

            // Update menu item state
            if let menu = statusItem?.menu,
                let muteItem = menu.items.first(where: { $0.title == "静音" })
            {
                muteItem.state = wallpaperEngine.globalMuted ? .on : .off
            }
        }

        @objc private func toggleDockIcon() {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                if NSApp.activationPolicy() == .regular {
                    appDelegate.hideDockIcon()
                    if let menu = statusItem?.menu,
                        let item = menu.items.first(where: { $0.title.contains("Dock") })
                    {
                        item.title = "显示 Dock 图标"
                    }
                } else {
                    appDelegate.showDockIcon()
                    if let menu = statusItem?.menu,
                        let item = menu.items.first(where: { $0.title.contains("Dock") })
                    {
                        item.title = "隐藏 Dock 图标"
                    }
                }
            }
        }

        @objc private func showAbout() {
            NSApp.orderFrontStandardAboutPanel(nil)
            NSApp.activate(ignoringOtherApps: true)
        }

        @objc private func quit() {
            NSApp.terminate(nil)
        }
    }
#endif
