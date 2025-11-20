// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MacWallpaper",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "MacWallpaper",
            targets: ["MacWallpaper"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MacWallpaper",
            path: "Sources/MacWallpaper"
        ),
    ]
)
