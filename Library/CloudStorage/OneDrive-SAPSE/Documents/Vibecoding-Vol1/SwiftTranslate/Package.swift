// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftTranslate",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.2.0")
    ],
    targets: [
        .executableTarget(
            name: "SwiftTranslate",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ],
            path: "SwiftTranslate",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SwiftTranslateTests",
            dependencies: ["SwiftTranslate"],
            path: "SwiftTranslateTests"
        )
    ]
)
