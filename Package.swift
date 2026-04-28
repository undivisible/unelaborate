// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "unelaborate",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "unelaborate", targets: ["LauncherApp"])
    ],
    targets: [
        .executableTarget(
            name: "LauncherApp",
            path: "Sources/LauncherApp"
        )
    ]
)
