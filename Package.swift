// swift-tools-version: 6.0

import Foundation
import PackageDescription

func isXcodeVersionAtLeast(_ versionString: String) -> Bool {
    let env = ProcessInfo.processInfo.environment
    let pattern = #"(?i)Xcode[_-]?([0-9]+(?:\.[0-9]+)*)"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
    for key in ["DEVELOPER_DIR", "SDKROOT", "PATH", "MANPATH"] {
        guard
            let path = env[key],
            let match = regex.firstMatch(in: path, range: NSRange(path.startIndex..., in: path)),
            let range = Range(match.range(at: 1), in: path)
        else {
            continue
        }
        let detectedVersion = String(path[range])
        let isMatch = detectedVersion.compare(versionString, options: .numeric) != .orderedAscending
        return isMatch
    }
    return false
}

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
        .package(url: "https://github.com/nathantannar4/Engine", from: "2.19.0"),
    ],
    targets: [
        .target(
            name: "Transmission",
            dependencies: [
                "Engine",
            ],
            swiftSettings: {
                var settings = [SwiftSetting]()
                #if compiler(>=6.2)
                settings.append(.define("XCODE_26"))
                #endif
                #if compiler(>=6.4)
                settings.append(.define("XCODE_27"))
                if isXcodeVersionAtLeast("27.1") {
                    settings.append(.define("XCODE_27_1"))
                }
                #endif
                return settings
            }()
        )
    ]
)
