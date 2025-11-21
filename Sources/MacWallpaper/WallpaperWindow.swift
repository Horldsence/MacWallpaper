import Foundation

#if os(macOS)
    import AppKit
    import AVFoundation

    @MainActor
    class WallpaperWindow: NSWindow {
        private var playerView: VideoPlayerView?

        init(screen: NSScreen) {
            super.init(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )

            self.setFrame(screen.frame, display: true)

            // Critical: Set window level to desktop layer
            self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))

            // Critical: Proper collection behavior
            self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

            self.isMovable = false
            self.isOpaque = false
            self.backgroundColor = .black
            self.hasShadow = false
            self.ignoresMouseEvents = true

            setupPlayerView()

            // Critical: Order window properly
            self.orderBack(nil)
        }

        private func setupPlayerView() {
            playerView = VideoPlayerView(frame: self.contentView!.bounds)
            playerView?.autoresizingMask = [.width, .height]
            self.contentView?.addSubview(playerView!)
        }

        func loadVideo(
            url: URL, muted: Bool, quality: VideoQuality,
            contentMode: ContentMode
        ) {
            playerView?.loadVideo(url: url, muted: muted, contentMode: contentMode)
        }

        func pauseVideo() {
            playerView?.pause()
        }

        func resumeVideo() {
            playerView?.resume()
        }

        func stopVideo() {
            playerView?.stop()
        }

        func setMuted(_ muted: Bool) {
            playerView?.setMuted(muted)
        }

        func setContentMode(_ contentMode: ContentMode) {
            playerView?.setContentMode(contentMode)
        }
    }

    @MainActor
    class VideoPlayerView: NSView {
        private var player: AVQueuePlayer?
        private var playerLayer: AVPlayerLayer?
        private var playerLooper: AVPlayerLooper?

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setupLayer()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupLayer()
        }

        private func setupLayer() {
            self.wantsLayer = true
            self.layer?.backgroundColor = NSColor.black.cgColor
        }

        func loadVideo(url: URL, muted: Bool, contentMode: ContentMode) {
            // Clean up existing player properly
            cleanupPlayer()

            // Create new player item
            let playerItem = AVPlayerItem(url: url)

            // Create queue player
            let queuePlayer = AVQueuePlayer(playerItem: playerItem)

            // Setup looping
            playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

            // Create player layer
            let newPlayerLayer = AVPlayerLayer(player: queuePlayer)
            newPlayerLayer.frame = self.bounds
            newPlayerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            newPlayerLayer.videoGravity = contentMode.videoGravity

            // Critical: Ensure layer is added to correct parent
            if let parentLayer = self.layer {
                parentLayer.addSublayer(newPlayerLayer)
            }

            self.playerLayer = newPlayerLayer
            self.player = queuePlayer

            // Set volume
            queuePlayer.isMuted = muted

            // Enable video tracks explicitly
            for track in playerItem.tracks {
                track.isEnabled = true
            }

            // Start playing
            queuePlayer.play()

            print("Video loaded: \(url.lastPathComponent), playing: \(queuePlayer.rate != 0)")
        }

        func pause() {
            // Pause but keep frame visible
            player?.pause()
            print("Video paused, frame preserved")
        }

        func resume() {
            // Resume from paused state
            player?.play()
            print("Video resumed")
        }

        func stop() {
            // Pause first to stop any ongoing playback
            player?.pause()

            // Use async cleanup to avoid CA crashes
            cleanupPlayer()
        }

        private func cleanupPlayer() {
            guard player != nil || playerLayer != nil else { return }

            // Pause if playing
            player?.pause()

            // Remove layer from superlayer on next runloop
            if let layer = playerLayer {
                // Use CATransaction to ensure cleanup happens safely
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                layer.removeFromSuperlayer()
                CATransaction.commit()
            }

            // Clear references after a brief delay to let CA finish
            DispatchQueue.main.async { [weak self] in
                self?.playerLayer = nil
                self?.player = nil
                self?.playerLooper = nil
            }
        }

        func setMuted(_ muted: Bool) {
            player?.isMuted = muted
        }

        func setContentMode(_ contentMode: ContentMode) {
            playerLayer?.videoGravity = contentMode.videoGravity
        }

        override func layout() {
            super.layout()
            playerLayer?.frame = self.bounds
        }
    }
#endif
