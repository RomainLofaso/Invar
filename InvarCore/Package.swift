// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "InvarCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "InvarCore",
            targets: ["InvarCore"]
        )
    ],
    targets: [
        .target(
            name: "InvarCore",
            dependencies: []
        )
    ]
)
