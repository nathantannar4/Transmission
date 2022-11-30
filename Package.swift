// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Transmission",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13),
    ],
    products: [
        .library(
            name: "Transmission",
            targets: ["Transmission"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/nathantannar4/Engine", from: "0.1.1"),
        .package(url: "https://github.com/nathantannar4/Turbocharger", from: "0.1.1"),
    ],
    targets: [
        .target(
            name: "Transmission",
            dependencies: [
                "Engine",
                "Turbocharger",
            ]
        )
    ]
)
