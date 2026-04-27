// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Transmission",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Transmission",
            targets: ["Transmission"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/nathantannar4/Engine", from: "2.7.0"),
    ],
    targets: [
        .target(
            name: "Transmission",
            dependencies: [
                "Engine",
            ]
        )
    ]
)
