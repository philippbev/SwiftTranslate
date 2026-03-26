// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftTranslate",
    defaultLocalization: "de",
    platforms: [.macOS(.v14)],
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
            exclude: ["Support"],
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("Translation"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .testTarget(
            name: "SwiftTranslateTests",
            dependencies: ["SwiftTranslate"],
            path: "SwiftTranslateTests"
        )
    ]
)
