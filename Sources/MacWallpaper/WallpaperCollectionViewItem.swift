import Foundation

#if os(macOS)
    import AppKit
    import AVFoundation

    @MainActor
    protocol WallpaperCollectionViewItemDelegate: AnyObject {
        func wallpaperItemDidDoubleClick(
            _ item: WallpaperCollectionViewItem, wallpaper: WallpaperItem)
        func wallpaperItemDidRightClick(
            _ item: WallpaperCollectionViewItem, wallpaper: WallpaperItem, event: NSEvent)
    }

    class WallpaperCollectionViewItem: NSCollectionViewItem {
        static let identifier = NSUserInterfaceItemIdentifier("WallpaperCollectionViewItem")

        weak var delegate: WallpaperCollectionViewItemDelegate?
        private var currentWallpaper: WallpaperItem?
        private var isCurrentlyApplied: Bool = false

        private var thumbnailImageView: NSImageView!
        private var nameLabel: NSTextField!
        private var containerView: NSView!
        private var currentIndicatorView: NSView!
        private var favoriteIndicatorView: NSImageView!

        override func loadView() {
            view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 180))
            view.wantsLayer = true

            setupContainerView()
            setupThumbnailImageView()
            setupNameLabel()
            setupCurrentIndicator()
            setupFavoriteIndicator()
            setupGestureRecognizers()
        }

        private func setupContainerView() {
            containerView = NSView(frame: view.bounds)
            containerView.wantsLayer = true
            containerView.layer?.cornerRadius = 8
            containerView.layer?.borderWidth = 2
            containerView.layer?.borderColor = NSColor.clear.cgColor
            containerView.autoresizingMask = [.width, .height]
            view.addSubview(containerView)
        }

        private func setupThumbnailImageView() {
            thumbnailImageView = NSImageView(frame: NSRect(x: 0, y: 30, width: 200, height: 130))
            thumbnailImageView.imageScaling = .scaleProportionallyUpOrDown
            thumbnailImageView.wantsLayer = true
            thumbnailImageView.layer?.cornerRadius = 8
            thumbnailImageView.layer?.masksToBounds = true
            thumbnailImageView.layer?.backgroundColor = NSColor.darkGray.cgColor
            thumbnailImageView.autoresizingMask = [.width, .height]
            containerView.addSubview(thumbnailImageView)
        }

        private func setupNameLabel() {
            nameLabel = NSTextField(frame: NSRect(x: 10, y: 5, width: 180, height: 20))
            nameLabel.isEditable = false
            nameLabel.isBordered = false
            nameLabel.backgroundColor = .clear
            nameLabel.alignment = .center
            nameLabel.font = .systemFont(ofSize: 12)
            nameLabel.lineBreakMode = .byTruncatingTail
            nameLabel.autoresizingMask = [.width]
            containerView.addSubview(nameLabel)
        }

        private func setupCurrentIndicator() {
            currentIndicatorView = NSView(frame: NSRect(x: 5, y: 155, width: 12, height: 12))
            currentIndicatorView.wantsLayer = true
            currentIndicatorView.layer?.backgroundColor = NSColor.systemGreen.cgColor
            currentIndicatorView.layer?.cornerRadius = 6
            currentIndicatorView.layer?.borderColor = NSColor.white.cgColor
            currentIndicatorView.layer?.borderWidth = 2
            currentIndicatorView.isHidden = true
            containerView.addSubview(currentIndicatorView)
        }

        private func setupFavoriteIndicator() {
            favoriteIndicatorView = NSImageView(
                frame: NSRect(x: 180, y: 155, width: 16, height: 16))
            favoriteIndicatorView.image = NSImage(
                systemSymbolName: "star.fill", accessibilityDescription: "喜欢")
            favoriteIndicatorView.contentTintColor = .systemYellow
            favoriteIndicatorView.isHidden = true
            containerView.addSubview(favoriteIndicatorView)
        }

        private func setupGestureRecognizers() {
            // Double-click recognizer
            let doubleClickGesture = NSClickGestureRecognizer(
                target: self, action: #selector(handleDoubleClick(_:)))
            doubleClickGesture.numberOfClicksRequired = 2
            view.addGestureRecognizer(doubleClickGesture)

            // Right-click recognizer
            let rightClickGesture = NSClickGestureRecognizer(
                target: self, action: #selector(handleRightClick(_:)))
            rightClickGesture.buttonMask = 0x2  // Right mouse button
            view.addGestureRecognizer(rightClickGesture)
        }

        func configure(with wallpaper: WallpaperItem, isCurrentlyApplied: Bool) {
            currentWallpaper = wallpaper
            self.isCurrentlyApplied = isCurrentlyApplied
            nameLabel.stringValue = wallpaper.name

            // Show/hide current indicator
            currentIndicatorView.isHidden = !isCurrentlyApplied

            // Show/hide favorite indicator
            favoriteIndicatorView.isHidden = !wallpaper.isFavorite

            // Load thumbnail
            if let thumbnailPath = wallpaper.thumbnailPath,
                let image = NSImage(contentsOfFile: thumbnailPath)
            {
                thumbnailImageView.image = image
            } else {
                // Generate thumbnail from video
                generateThumbnail(from: wallpaper.url)
            }
        }

        private func generateThumbnail(from url: URL) {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let asset = AVAsset(url: url)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                imageGenerator.maximumSize = CGSize(width: 400, height: 300)

                do {
                    let time = CMTime(seconds: 1, preferredTimescale: 1)
                    let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                    let image = NSImage(cgImage: cgImage, size: .zero)

                    DispatchQueue.main.async {
                        self?.thumbnailImageView.image = image
                    }
                } catch {
                    print("Error generating thumbnail: \(error)")
                    DispatchQueue.main.async {
                        // Use default video icon
                        self?.thumbnailImageView.image = NSImage(
                            systemSymbolName: "film", accessibilityDescription: "Video")
                    }
                }
            }
        }

        @objc private func handleDoubleClick(_ gesture: NSClickGestureRecognizer) {
            guard let wallpaper = currentWallpaper else { return }
            delegate?.wallpaperItemDidDoubleClick(self, wallpaper: wallpaper)
        }

        @objc private func handleRightClick(_ gesture: NSClickGestureRecognizer) {
            guard let wallpaper = currentWallpaper,
                let event = NSApp.currentEvent
            else { return }
            delegate?.wallpaperItemDidRightClick(self, wallpaper: wallpaper, event: event)
        }

        override var isSelected: Bool {
            didSet {
                updateBorderColor()
            }
        }

        private func updateBorderColor() {
            if isSelected {
                containerView.layer?.borderColor = NSColor.controlAccentColor.cgColor
            } else if isCurrentlyApplied {
                containerView.layer?.borderColor =
                    NSColor.systemGreen.withAlphaComponent(0.5).cgColor
            } else {
                containerView.layer?.borderColor = NSColor.clear.cgColor
            }
        }
    }
#endif
