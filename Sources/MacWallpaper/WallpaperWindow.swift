import Foundation

#if os(macOS)
import AppKit
import AVFoundation

class WallpaperWindow: NSWindow {
    private var playerView: VideoPlayerView?
    
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        self.level = .init(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.isMovable = false
        self.backgroundColor = .black
        
        setupPlayerView()
    }
    
    private func setupPlayerView() {
        playerView = VideoPlayerView(frame: self.contentView!.bounds)
        playerView?.autoresizingMask = [.width, .height]
        self.contentView?.addSubview(playerView!)
    }
    
    func loadVideo(url: URL, muted: Bool, quality: WallpaperEngine.VideoQuality) {
        playerView?.loadVideo(url: url, muted: muted)
    }
    
    func stopVideo() {
        playerView?.stop()
    }
    
    func setMuted(_ muted: Bool) {
        playerView?.setMuted(muted)
    }
}

class VideoPlayerView: NSView {
    private var player: AVPlayer?
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
    
    func loadVideo(url: URL, muted: Bool) {
        // Stop existing player
        stop()
        
        // Create new player
        let playerItem = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        
        // Setup looping
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        // Create player layer
        playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer?.frame = self.bounds
        playerLayer?.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        playerLayer?.videoGravity = .resizeAspectFill
        
        self.layer?.addSublayer(playerLayer!)
        
        // Set volume
        queuePlayer.isMuted = muted
        
        // Start playing
        player = queuePlayer
        player?.play()
    }
    
    func stop() {
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
        playerLooper = nil
    }
    
    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
    }
    
    override func layout() {
        super.layout()
        playerLayer?.frame = self.bounds
    }
}
#endif
