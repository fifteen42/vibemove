// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VibeMove",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "VibeMove",
            path: "Sources/VibeMove",
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/VibeMove/Info.plist",
                ])
            ]
        )
    ]
)
