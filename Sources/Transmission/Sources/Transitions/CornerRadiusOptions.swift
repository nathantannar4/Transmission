//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

@frozen
public enum CornerRadiusOptions: Equatable, Sendable {

    @frozen
    public struct RoundedRectangle: Equatable, Sendable {
        public var cornerRadius: CGFloat
        public var mask: CACornerMask
        public var style: CALayerCornerCurve

        private init(
            cornerRadius: CGFloat,
            mask: CACornerMask,
            style: CALayerCornerCurve
        ) {
            self.cornerRadius = cornerRadius
            self.mask = mask
            self.style = style
        }

        public static let identity: RoundedRectangle = .rounded(cornerRadius: 0)

        public static func rounded(
            cornerRadius: CGFloat,
            mask: CACornerMask,
            style: CALayerCornerCurve
        ) -> RoundedRectangle {
            RoundedRectangle(
                cornerRadius: cornerRadius,
                mask: mask,
                style: style
            )
        }

        public static func rounded(
            cornerRadius: CGFloat,
            style: CALayerCornerCurve = .circular
        ) -> RoundedRectangle {
            .rounded(
                cornerRadius: cornerRadius,
                mask: .all,
                style: style
            )
        }

        @MainActor @preconcurrency
        public static func screen(
            min: CGFloat = 12
        ) -> RoundedRectangle {
            .rounded(
                cornerRadius: UIScreen.main.displayCornerRadius(min: min),
                style: .continuous
            )
        }
    }

    @frozen
    public struct Capsule: Equatable, Sendable {
        public var maxCornerRadius: CGFloat?
        public var style: CALayerCornerCurve
    }

    case rounded(RoundedRectangle)
    case circle
    case capsule(Capsule)

    public var mask: CACornerMask {
        switch self {
        case .rounded(let options):
            return options.mask
        case .circle, .capsule:
            return .all
        }
    }

    public var style: CALayerCornerCurve {
        switch self {
        case .rounded(let options):
            return options.style
        case .circle:
            return .circular
        case .capsule(let options):
            return options.style
        }
    }

    public func cornerRadius(for height: CGFloat) -> CGFloat {
        switch self {
        case .rounded(let options):
            return options.cornerRadius
        case .circle:
            return height / 2
        case .capsule(let options):
            return min(height / 2, options.maxCornerRadius ?? height)
        }
    }

    public static func rounded(
        cornerRadius: CGFloat,
        style: CALayerCornerCurve = .circular
    ) -> CornerRadiusOptions {
        .rounded(
            cornerRadius: cornerRadius,
            mask: .all,
            style: style
        )
    }

    public static func rounded(
        cornerRadius: CGFloat,
        mask: CACornerMask,
        style: CALayerCornerCurve
    ) -> CornerRadiusOptions {
        .rounded(
            .rounded(
                cornerRadius: cornerRadius,
                mask: mask,
                style: style
            )
        )
    }

    public static var capsule: CornerRadiusOptions {
        .capsule(maxCornerRadius: nil)
    }

    public static func capsule(
        maxCornerRadius: CGFloat?,
        style: CALayerCornerCurve = .circular
    ) -> CornerRadiusOptions {
        .capsule(
            Capsule(
                maxCornerRadius: maxCornerRadius,
                style: style
            )
        )
    }

    public static let identity: CornerRadiusOptions = .rounded(cornerRadius: 0)

    @MainActor @preconcurrency
    public func apply(to layer: CALayer, height: CGFloat) {
        switch self {
        case .rounded(let options):
            options.apply(to: layer)
        case .circle, .capsule:
            layer.cornerRadius = cornerRadius(for: height)
            layer.maskedCorners = mask
            layer.cornerCurve = style
        }
    }
}

extension CornerRadiusOptions.RoundedRectangle {

    @MainActor @preconcurrency
    public func apply(to layer: CALayer, masksToBounds: Bool = true) {
        let cornerRadius = cornerRadius
        layer.cornerRadius = cornerRadius
        layer.maskedCorners = mask
        layer.cornerCurve = style
        layer.masksToBounds = masksToBounds && cornerRadius > 0
    }
}

extension CACornerMask {
    static let all: CACornerMask = [
        .layerMaxXMaxYCorner,
        .layerMaxXMinYCorner,
        .layerMinXMaxYCorner,
        .layerMinXMinYCorner
    ]
}

#endif
