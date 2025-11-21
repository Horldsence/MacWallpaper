import Foundation

#if os(macOS)
    import AppKit

    class SettingsPanel: NSWindowController {
        private var wallpaperEngine: WallpaperEngine
        private var appSettings: AppSettings
        // Keep references to controls that need dynamic enable/disable
        private var smartPauseCheckbox: NSButton?
        private var pauseMaximizedCheckbox: NSButton?
        private var pauseLowPowerCheckbox: NSButton?

        init(wallpaperEngine: WallpaperEngine) {
            self.wallpaperEngine = wallpaperEngine
            self.appSettings = AppSettings.load()

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 450),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )

            super.init(window: window)

            window.title = "设置"
            window.center()

            setupContentView()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupContentView() {
            guard let contentView = window?.contentView else { return }

            let stackView = NSStackView(frame: contentView.bounds)
            stackView.orientation = .vertical
            stackView.alignment = .leading
            stackView.spacing = 15
            stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            stackView.autoresizingMask = [.width, .height]

            // Title
            let titleLabel = NSTextField(labelWithString: "全局设置")
            titleLabel.font = .boldSystemFont(ofSize: 16)
            stackView.addArrangedSubview(titleLabel)

            // Separator
            let separator1 = NSBox()
            separator1.boxType = .separator
            stackView.addArrangedSubview(separator1)

            // Playback Settings Section
            let playbackSectionLabel = NSTextField(labelWithString: "播放设置")
            playbackSectionLabel.font = .boldSystemFont(ofSize: 13)
            stackView.addArrangedSubview(playbackSectionLabel)

            // Mute setting
            let muteCheckbox = NSButton(
                checkboxWithTitle: "静音播放", target: self, action: #selector(muteToggled(_:)))
            muteCheckbox.state = wallpaperEngine.globalMuted ? .on : .off
            stackView.addArrangedSubview(muteCheckbox)

            // Quality setting
            let qualityLabel = NSTextField(labelWithString: "播放质量:")
            stackView.addArrangedSubview(qualityLabel)

            let qualityPopup = NSPopUpButton(
                frame: NSRect(x: 0, y: 0, width: 200, height: 26), pullsDown: false)
            for quality in VideoQuality.allCases {
                qualityPopup.addItem(withTitle: quality.description)
            }
            qualityPopup.selectItem(withTitle: wallpaperEngine.quality.description)
            qualityPopup.target = self
            qualityPopup.action = #selector(qualityChanged(_:))
            stackView.addArrangedSubview(qualityPopup)

            // Separator
            let separator2 = NSBox()
            separator2.boxType = .separator
            stackView.addArrangedSubview(separator2)

            // Interface Settings Section
            let interfaceSectionLabel = NSTextField(labelWithString: "界面设置")
            interfaceSectionLabel.font = .boldSystemFont(ofSize: 13)
            stackView.addArrangedSubview(interfaceSectionLabel)

            // Show toolbar labels
            let showLabelsCheckbox = NSButton(
                checkboxWithTitle: "显示工具栏文字标签",
                target: self,
                action: #selector(showLabelsToggled(_:)))
            showLabelsCheckbox.state = appSettings.showToolbarLabels ? .on : .off
            stackView.addArrangedSubview(showLabelsCheckbox)

            // Separator
            let separator3 = NSBox()
            separator3.boxType = .separator
            stackView.addArrangedSubview(separator3)

            // Auto-pause Settings Section
            let autoPauseSectionLabel = NSTextField(labelWithString: "自动暂停")
            autoPauseSectionLabel.font = .boldSystemFont(ofSize: 13)
            stackView.addArrangedSubview(autoPauseSectionLabel)

            // Smart pause setting
            let smartCheckbox = NSButton(
                checkboxWithTitle: "智能暂停（自动启用其它暂停选项并锁定）",
                target: self,
                action: #selector(smartPauseToggled(_:)))
            smartCheckbox.state = appSettings.smartPause ? .on : .off
            stackView.addArrangedSubview(smartCheckbox)
            self.smartPauseCheckbox = smartCheckbox

            // Pause when window maximized
            let pauseMaximizedCheckbox = NSButton(
                checkboxWithTitle: "窗口最大化时暂停壁纸",
                target: self,
                action: #selector(pauseMaximizedToggled(_:)))
            pauseMaximizedCheckbox.state = appSettings.pauseWhenWindowMaximized ? .on : .off
            stackView.addArrangedSubview(pauseMaximizedCheckbox)
            self.pauseMaximizedCheckbox = pauseMaximizedCheckbox

            // Pause when low power mode
            let pauseLowPowerCheckbox = NSButton(
                checkboxWithTitle: "省电模式时暂停壁纸",
                target: self,
                action: #selector(pauseLowPowerToggled(_:)))
            pauseLowPowerCheckbox.state = appSettings.pauseWhenLowPowerMode ? .on : .off
            stackView.addArrangedSubview(pauseLowPowerCheckbox)
            self.pauseLowPowerCheckbox = pauseLowPowerCheckbox

            // Apply smartPause constraint: when smartPause is on, force others on and disable them
            applySmartPauseUIState()

            // Spacer
            let spacer = NSView()
            spacer.translatesAutoresizingMaskIntoConstraints = false
            spacer.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
            stackView.addArrangedSubview(spacer)

            // Info
            let infoLabel = NSTextField(
                wrappingLabelWithString:
                    "提示: 质量设置变更后，需要重新选择壁纸以应用。界面和自动暂停设置将立即生效。")
            infoLabel.font = .systemFont(ofSize: 11)
            infoLabel.textColor = .secondaryLabelColor
            infoLabel.preferredMaxLayoutWidth = 410
            stackView.addArrangedSubview(infoLabel)

            contentView.addSubview(stackView)
        }

        @objc private func muteToggled(_ sender: NSButton) {
            wallpaperEngine.globalMuted = (sender.state == .on)
        }

        @objc private func qualityChanged(_ sender: NSPopUpButton) {
            guard let selectedTitle = sender.selectedItem?.title else { return }

            if let quality = VideoQuality.allCases.first(where: { $0.description == selectedTitle })
            {
                wallpaperEngine.quality = quality
            }
        }

        @objc private func showLabelsToggled(_ sender: NSButton) {
            appSettings.showToolbarLabels = (sender.state == .on)
            appSettings.save()

            // Update all toolbar display modes
            for window in NSApp.windows {
                if let toolbar = window.toolbar {
                    toolbar.displayMode = appSettings.showToolbarLabels ? .iconAndLabel : .iconOnly
                }
            }
        }

        @objc private func pauseMaximizedToggled(_ sender: NSButton) {
            // If smartPause is enabled, ignore changes (controls should be disabled anyway)
            guard !appSettings.smartPause else {
                // Ensure UI reflects that it's forced on
                sender.state = .on
                return
            }

            appSettings.pauseWhenWindowMaximized = (sender.state == .on)
            appSettings.save()
            wallpaperEngine.appSettings = appSettings
        }

        @objc private func pauseLowPowerToggled(_ sender: NSButton) {
            guard !appSettings.smartPause else {
                sender.state = .on
                return
            }

            appSettings.pauseWhenLowPowerMode = (sender.state == .on)
            appSettings.save()
            wallpaperEngine.appSettings = appSettings
        }

        @objc private func smartPauseToggled(_ sender: NSButton) {
            let enabled = (sender.state == .on)
            appSettings.smartPause = enabled

            if enabled {
                // Force other options on and lock them
                appSettings.pauseWhenWindowMaximized = true
                appSettings.pauseWhenLowPowerMode = true
            } else {
                // When disabled, keep 2 & 3 enabled but allow modification
                // They already default to true in AppSettings; leave current values
            }

            appSettings.save()
            wallpaperEngine.appSettings = appSettings

            applySmartPauseUIState()
        }

        private func applySmartPauseUIState() {
            let isSmart = appSettings.smartPause

            // If smartPause is enabled, force checkboxes on and disable interaction
            if isSmart {
                pauseMaximizedCheckbox?.state = .on
                pauseLowPowerCheckbox?.state = .on
                pauseMaximizedCheckbox?.isEnabled = false
                pauseLowPowerCheckbox?.isEnabled = false
            } else {
                // Keep current values but enable controls for user editing
                pauseMaximizedCheckbox?.isEnabled = true
                pauseLowPowerCheckbox?.isEnabled = true
                pauseMaximizedCheckbox?.state = appSettings.pauseWhenWindowMaximized ? .on : .off
                pauseLowPowerCheckbox?.state = appSettings.pauseWhenLowPowerMode ? .on : .off
            }
        }
    }
#endif
