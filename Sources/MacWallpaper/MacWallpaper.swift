import Foundation

#if os(macOS)
import AppKit

@main
class MacWallpaper {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
#else
@main
struct MacWallpaper {
    static func main() {
        print("This application is designed for macOS only.")
    }
}
#endif
