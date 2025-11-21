import Foundation

#if os(macOS)
    import AppKit
    import AVFoundation

    @MainActor
    protocol InspectorViewDelegate: AnyObject {
        func inspectorDidRequestApply(_ wallpaper: WallpaperItem)
        func inspectorDidChangeMute(_ wallpaper: WallpaperItem, muted: Bool)
        func inspectorDidChangeQuality(_ quality: VideoQuality)
        func inspectorDidChangeContentMode(_ contentMode: ContentMode)
    }

    @MainActor
    class InspectorView: NSView {
        weak var delegate: InspectorViewDelegate?

        private var currentWallpaper: WallpaperItem?

        private var thumbnailImageView: NSImageView!
        private var nameLabel: NSTextField!
        private var applyButton: NSButton!
        private var muteCheckbox: NSButton!
        private var qualityPopup: NSPopUpButton!
        private var contentModePopup: NSPopUpButton!
        private var stackView: NSStackView!

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setupView()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupView()
        }

        private func setupView() {
            print("🔧 InspectorView setupView called, frame: \(frame)")

            wantsLayer = true
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

            stackView = NSStackView()
            stackView.orientation = .vertical
            stackView.alignment = .centerX
            stackView.spacing = 16
            stackView.edgeInsets = NSEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
            stackView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            ])

            setupThumbnail()
            setupNameLabel()
            setupApplyButton()
            setupSeparator()
            setupMuteControl()
            setupQualityControl()
            setupContentModeControl()

            configure(with: nil)

            print("🔧 InspectorView setup complete, subviews: \(stackView.arrangedSubviews.count)")
        }

        private func setupThumbnail() {
            thumbnailImageView = NSImageView()
            thumbnailImageView.imageScaling = .scaleProportionallyUpOrDown
            thumbnailImageView.wantsLayer = true
            thumbnailImageView.layer?.cornerRadius = 8
            thumbnailImageView.layer?.masksToBounds = true
            thumbnailImageView.layer?.backgroundColor = NSColor.darkGray.cgColor
            thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false

            stackView.addArrangedSubview(thumbnailImageView)

            NSLayoutConstraint.activate([
                thumbnailImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 218),
                thumbnailImageView.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),
                thumbnailImageView.heightAnchor.constraint(equalToConstant: 140),
            ])
        }

        private func setupNameLabel() {
            nameLabel = NSTextField(labelWithString: "未选择壁纸")
            nameLabel.font = .boldSystemFont(ofSize: 14)
            nameLabel.alignment = .center
            nameLabel.lineBreakMode = .byWordWrapping
            nameLabel.maximumNumberOfLines = 2
            nameLabel.translatesAutoresizingMaskIntoConstraints = false

            // Prevent label from expanding container
            nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

            stackView.addArrangedSubview(nameLabel)

            NSLayoutConstraint.activate([
                nameLabel.widthAnchor.constraint(
                    lessThanOrEqualTo: stackView.widthAnchor, constant: -32)
            ])
        }

        private func setupApplyButton() {
            applyButton = NSButton(
                title: "应用壁纸", target: self, action: #selector(applyButtonClicked))
            applyButton.bezelStyle = .rounded
            applyButton.translatesAutoresizingMaskIntoConstraints = false

            stackView.addArrangedSubview(applyButton)

            NSLayoutConstraint.activate([
                applyButton.widthAnchor.constraint(equalToConstant: 120)
            ])
        }

        private func setupSeparator() {
            let separator = NSBox()
            separator.boxType = .separator
            separator.translatesAutoresizingMaskIntoConstraints = false

            stackView.addArrangedSubview(separator)

            NSLayoutConstraint.activate([
                separator.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -16),
                separator.heightAnchor.constraint(equalToConstant: 1),
            ])
        }

        private func setupMuteControl() {
            let container = NSView()
            container.translatesAutoresizingMaskIntoConstraints = false

            let label = NSTextField(labelWithString: "静音:")
            label.font = .systemFont(ofSize: 12)
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)

            muteCheckbox = NSButton(
                checkboxWithTitle: "", target: self, action: #selector(muteChanged))
            muteCheckbox.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(muteCheckbox)

            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                muteCheckbox.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                muteCheckbox.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                container.heightAnchor.constraint(equalToConstant: 24),
            ])

            stackView.addArrangedSubview(container)

            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -32)
            ])
        }

        private func setupQualityControl() {
            let container = NSView()
            container.translatesAutoresizingMaskIntoConstraints = false

            let label = NSTextField(labelWithString: "质量:")
            label.font = .systemFont(ofSize: 12)
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)

            qualityPopup = NSPopUpButton(frame: .zero, pullsDown: false)
            qualityPopup.translatesAutoresizingMaskIntoConstraints = false
            for quality in VideoQuality.allCases {
                qualityPopup.addItem(withTitle: quality.description)
            }
            qualityPopup.target = self
            qualityPopup.action = #selector(qualityChanged)
            container.addSubview(qualityPopup)

            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                qualityPopup.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                qualityPopup.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                qualityPopup.widthAnchor.constraint(equalToConstant: 100),
                container.heightAnchor.constraint(equalToConstant: 26),
            ])

            stackView.addArrangedSubview(container)

            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -32)
            ])
        }

        private func setupContentModeControl() {
            let container = NSView()
            container.translatesAutoresizingMaskIntoConstraints = false

            let label = NSTextField(labelWithString: "布局:")
            label.font = .systemFont(ofSize: 12)
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)

            contentModePopup = NSPopUpButton(frame: .zero, pullsDown: false)
            contentModePopup.translatesAutoresizingMaskIntoConstraints = false
            for mode in ContentMode.allCases {
                contentModePopup.addItem(withTitle: mode.description)
            }
            contentModePopup.target = self
            contentModePopup.action = #selector(contentModeChanged)
            container.addSubview(contentModePopup)

            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                contentModePopup.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                contentModePopup.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                contentModePopup.widthAnchor.constraint(equalToConstant: 100),
                container.heightAnchor.constraint(equalToConstant: 26),
            ])

            stackView.addArrangedSubview(container)

            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -32)
            ])
        }

        func configure(with wallpaper: WallpaperItem?) {
            currentWallpaper = wallpaper

            print("🎨 InspectorView configure called with: \(wallpaper?.name ?? "nil")")
            print("🎨 InspectorView frame: \(frame), hidden: \(isHidden)")

            if let wallpaper = wallpaper {
                nameLabel.stringValue = wallpaper.name
                applyButton.isEnabled = true
                muteCheckbox.state = wallpaper.isMuted ? .on : .off

                if let thumbnailPath = wallpaper.thumbnailPath,
                    let image = NSImage(contentsOfFile: thumbnailPath)
                {
                    thumbnailImageView.image = image
                } else {
                    generateThumbnail(from: wallpaper.url)
                }
            } else {
                nameLabel.stringValue = "未选择壁纸"
                applyButton.isEnabled = false
                thumbnailImageView.image = NSImage(
                    systemSymbolName: "photo", accessibilityDescription: "无壁纸")
            }

            // Force layout update
            needsLayout = true
            layoutSubtreeIfNeeded()

            print("🎨 InspectorView after configure - stackView frame: \(stackView.frame)")
        }

        func updateEngineState(
            quality: VideoQuality,
            contentMode: ContentMode
        ) {
            qualityPopup.selectItem(withTitle: quality.description)
            contentModePopup.selectItem(withTitle: contentMode.description)
        }

        func updateWallpaperMuteState(_ muted: Bool) {
            muteCheckbox.state = muted ? .on : .off
        }

        private func generateThumbnail(from url: URL) {
            thumbnailImageView.image = NSImage(
                systemSymbolName: "film", accessibilityDescription: "加载中")

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }

                let asset = AVAsset(url: url)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                imageGenerator.maximumSize = CGSize(width: 400, height: 300)

                do {
                    let time = CMTime(seconds: 1, preferredTimescale: 1)
                    let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                    let image = NSImage(cgImage: cgImage, size: .zero)

                    DispatchQueue.main.async {
                        self.thumbnailImageView.image = image
                    }
                } catch {
                    print("Error generating thumbnail: \(error)")
                }
            }
        }

        @objc private func applyButtonClicked() {
            guard let wallpaper = currentWallpaper else { return }
            delegate?.inspectorDidRequestApply(wallpaper)
        }

        @objc private func muteChanged() {
            guard let wallpaper = currentWallpaper else { return }
            let muted = muteCheckbox.state == .on
            delegate?.inspectorDidChangeMute(wallpaper, muted: muted)
        }

        @objc private func qualityChanged() {
            guard let selectedTitle = qualityPopup.selectedItem?.title,
                let quality = VideoQuality.allCases.first(where: {
                    $0.description == selectedTitle
                })
            else { return }

            delegate?.inspectorDidChangeQuality(quality)
        }

        @objc private func contentModeChanged() {
            guard let selectedTitle = contentModePopup.selectedItem?.title,
                let mode = ContentMode.allCases.first(where: {
                    $0.description == selectedTitle
                })
            else { return }

            delegate?.inspectorDidChangeContentMode(mode)
        }
    }
#endif
