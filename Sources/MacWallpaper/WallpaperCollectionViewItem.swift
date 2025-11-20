import Foundation

#if os(macOS)
import AppKit
import AVFoundation

class WallpaperCollectionViewItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("WallpaperCollectionViewItem")
    
    private var thumbnailImageView: NSImageView!
    private var nameLabel: NSTextField!
    private var containerView: NSView!
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 180))
        view.wantsLayer = true
        
        setupContainerView()
        setupThumbnailImageView()
        setupNameLabel()
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
    
    func configure(with wallpaper: WallpaperItem) {
        nameLabel.stringValue = wallpaper.name
        
        // Load thumbnail
        if let thumbnailPath = wallpaper.thumbnailPath,
           let image = NSImage(contentsOfFile: thumbnailPath) {
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
                    self?.thumbnailImageView.image = NSImage(systemSymbolName: "film", accessibilityDescription: "Video")
                }
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            containerView.layer?.borderColor = isSelected ? NSColor.controlAccentColor.cgColor : NSColor.clear.cgColor
        }
    }
}
#endif
