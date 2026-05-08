// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ClipboardLinkBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ClipboardLinkBar", targets: ["ClipboardLinkBar"])
    ],
    targets: [
        .executableTarget(name: "ClipboardLinkBar")
    ]
)
