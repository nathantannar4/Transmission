//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@frozen
@available(iOS 14.0, *)
public struct BackgroundOptions: Equatable, Sendable {

    public enum Material: Equatable, Sendable {
        /// A material that's somewhat translucent.
        case regular
        /// A material that's more opaque than translucent.
        case thick
        /// A material that's more translucent than opaque.
        case thin
        /// A mostly translucent material.
        case ultraThin
        /// A mostly opaque material.
        case ultraThick
    }

    public enum Glass: Equatable, Sendable {
        /// The regular variant of glass.
        case regular

        /// The clear variant of glass.
        case clear

        /// The tinted variant of glass.
        case tinted(Color)
    }

    public struct VisualEffect: Equatable, Sendable {
        enum Storage: Equatable, Sendable {
            case material(Material)
            case glass(Glass)
        }
        var storage: Storage

        @available(iOS 15.0, *)
        public static func material(_ material: Material) -> VisualEffect {
            VisualEffect(storage: .material(material))
        }

        @available(iOS 26.0, *)
        public static func glass(_ glass: Glass) -> VisualEffect {
            VisualEffect(storage: .glass(glass))
        }

        public static func glass(_ glass: Glass, otherwise fallback: VisualEffect) -> VisualEffect {
            if #available(iOS 26.0, *) {
                return .glass(glass)
            } else {
                return fallback
            }
        }
    }

    public var color: Color?
    public var effect: VisualEffect?

    public init(
        color: Color?,
        effect: VisualEffect?
    ) {
        self.color = color
        self.effect = effect
    }

    public static var clear: BackgroundOptions {
        .color(.clear)
    }

    public static func color(_ color: Color) -> BackgroundOptions {
        BackgroundOptions(color: color, effect: nil)
    }

    @available(iOS 15.0, *)
    public static func material(_ material: Material) -> BackgroundOptions {
        BackgroundOptions(color: nil, effect: .material(material))
    }

    @available(iOS 26.0, *)
    public static func glass(_ glass: Glass) -> BackgroundOptions {
        BackgroundOptions(color: nil, effect: .glass(glass))
    }

    public static func glass(_ glass: Glass, otherwise fallback: BackgroundOptions?) -> BackgroundOptions? {
        if #available(iOS 26.0, *) {
            return .glass(glass)
        } else {
            return fallback
        }
    }
}

@available(iOS 14.0, *)
extension BackgroundOptions.VisualEffect {

    @MainActor
    func toVisualEffect() -> UIVisualEffect? {
        switch storage {
        case .material(let material):
            let effect = UIBlurEffect(style: {
                switch material {
                case .regular:
                    return .regular
                case .thick:
                    return .systemThickMaterial
                case .thin:
                    return .systemThinMaterial
                case .ultraThin:
                    return .systemUltraThinMaterial
                case .ultraThick:
                    return .systemChromeMaterial
                }
            }())
            return effect
        case .glass(let glass):
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *) {
                let effect = UIGlassEffect(style: glass == .clear ? .clear : .regular)
                if case .tinted(let color) = glass {
                    effect.tintColor = color.toUIColor()
                }
                return effect
            }
            #endif
            return nil
        }
    }
}

#endif
