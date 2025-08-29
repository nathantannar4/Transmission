//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

@frozen
@MainActor @preconcurrency
public enum CornerRadiusOptions: Equatable, Sendable {

    @frozen
    @MainActor @preconcurrency
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

        public static func screen(
            min: CGFloat = 12
        ) -> RoundedRectangle {
            .rounded(
                cornerRadius: UIScreen.main.displayCornerRadius(min: min),
                style: .continuous
            )
        }
    }

    case rounded(RoundedRectangle)
    case circle

    public var mask: CACornerMask {
        switch self {
        case .rounded(let options):
            return options.mask
        case .circle:
            return .all
        }
    }

    public var style: CALayerCornerCurve {
        switch self {
        case .rounded(let options):
            return options.style
        case .circle:
            return .circular
        }
    }

    public func cornerRadius(for height: CGFloat) -> CGFloat {
        switch self {
        case .rounded(let options):
            return options.cornerRadius
        case .circle:
            return height / 2
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

    public static let identity: CornerRadiusOptions = .rounded(cornerRadius: 0)

    public func apply(to layer: CALayer, height: CGFloat) {
        switch self {
        case .rounded(let options):
            options.apply(to: layer)
        case .circle:
            layer.cornerRadius = cornerRadius(for: height)
            layer.maskedCorners = mask
            layer.cornerCurve = style
            layer.masksToBounds = true
        }
    }
}

extension CornerRadiusOptions.RoundedRectangle {
    public func apply(to layer: CALayer) {
        let cornerRadius = cornerRadius
        layer.cornerRadius = cornerRadius
        layer.maskedCorners = mask
        layer.cornerCurve = style
        layer.masksToBounds = cornerRadius > 0
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
