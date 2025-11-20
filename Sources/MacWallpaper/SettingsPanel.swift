import Foundation

#if os(macOS)
import AppKit

class SettingsPanel: NSWindowController {
    private var wallpaperEngine: WallpaperEngine
    
    init(wallpaperEngine: WallpaperEngine) {
        self.wallpaperEngine = wallpaperEngine
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
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
        stackView.spacing = 20
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stackView.autoresizingMask = [.width, .height]
        
        // Title
        let titleLabel = NSTextField(labelWithString: "壁纸设置")
        titleLabel.font = .boldSystemFont(ofSize: 16)
        stackView.addArrangedSubview(titleLabel)
        
        // Mute setting
        let muteCheckbox = NSButton(checkboxWithTitle: "静音播放", target: self, action: #selector(muteToggled(_:)))
        muteCheckbox.state = wallpaperEngine.isMuted ? .on : .off
        stackView.addArrangedSubview(muteCheckbox)
        
        // Quality setting
        let qualityLabel = NSTextField(labelWithString: "播放质量:")
        stackView.addArrangedSubview(qualityLabel)
        
        let qualityPopup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 200, height: 26), pullsDown: false)
        for quality in WallpaperEngine.VideoQuality.allCases {
            qualityPopup.addItem(withTitle: quality.description)
        }
        qualityPopup.selectItem(withTitle: wallpaperEngine.quality.description)
        qualityPopup.target = self
        qualityPopup.action = #selector(qualityChanged(_:))
        stackView.addArrangedSubview(qualityPopup)
        
        // Spacer
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        stackView.addArrangedSubview(spacer)
        
        // Info
        let infoLabel = NSTextField(wrappingLabelWithString: "提示: 更改设置后，需要重新选择壁纸以应用新设置。")
        infoLabel.font = .systemFont(ofSize: 11)
        infoLabel.textColor = .secondaryLabelColor
        infoLabel.preferredMaxLayoutWidth = 360
        stackView.addArrangedSubview(infoLabel)
        
        contentView.addSubview(stackView)
    }
    
    @objc private func muteToggled(_ sender: NSButton) {
        wallpaperEngine.isMuted = (sender.state == .on)
    }
    
    @objc private func qualityChanged(_ sender: NSPopUpButton) {
        guard let selectedTitle = sender.selectedItem?.title else { return }
        
        if let quality = WallpaperEngine.VideoQuality.allCases.first(where: { $0.description == selectedTitle }) {
            wallpaperEngine.quality = quality
        }
    }
}
#endif
