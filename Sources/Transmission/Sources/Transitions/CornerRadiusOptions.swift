//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

@frozen
public enum CornerRadiusOptions: Equatable, Sendable {

    @frozen
    public struct RoundedRectangle: Equatable, Sendable {
        public var cornerRadius: CGFloat?
        public var mask: CACornerMask
        public var style: CALayerCornerCurve
        public var isContainerConcentric: Bool

        private init(
            cornerRadius: CGFloat?,
            mask: CACornerMask,
            style: CALayerCornerCurve,
            isContainerConcentric: Bool = false
        ) {
            self.cornerRadius = cornerRadius
            self.mask = mask
            self.style = style
            self.isContainerConcentric = isContainerConcentric
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
            RoundedRectangle(
                cornerRadius: UIScreen.main.displayCornerRadius(min: min),
                mask: .all,
                style: .continuous
            )
        }

        public static func containerConcentric(
            minimum cornerRadius: CGFloat?,
            style: CALayerCornerCurve = .continuous
        ) -> RoundedRectangle {
            containerConcentric(
                minimum: cornerRadius,
                mask: .all,
                style: style
            )
        }

        public static func containerConcentric(
            minimum cornerRadius: CGFloat?,
            mask: CACornerMask,
            style: CALayerCornerCurve = .continuous
        ) -> RoundedRectangle {
            RoundedRectangle(
                cornerRadius: cornerRadius,
                mask: mask,
                style: style,
                isContainerConcentric: true
            )
        }
    }

    @frozen
    public struct Capsule: Equatable, Sendable {
        public var minCornerRadius: CGFloat?
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
            return options.cornerRadius ?? 0
        case .circle:
            return height / 2
        case .capsule(let options):
            return options.cornerRadius(for: height)
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

    public static func containerConcentric(
        minimum cornerRadius: CGFloat,
        style: CALayerCornerCurve = .continuous
    ) -> CornerRadiusOptions {
        containerConcentric(
            minimum: cornerRadius,
            mask: .all,
            style: style
        )
    }

    public static func containerConcentric(
        minimum cornerRadius: CGFloat,
        mask: CACornerMask,
        style: CALayerCornerCurve = .continuous
    ) -> CornerRadiusOptions {
        .rounded(
            .containerConcentric(
                minimum: cornerRadius,
                mask: mask,
                style: style
            )
        )
    }

    public static var capsule: CornerRadiusOptions {
        .capsule()
    }

    public static func capsule(
        minCornerRadius: CGFloat? = nil,
        maxCornerRadius: CGFloat? = nil,
        style: CALayerCornerCurve = .circular
    ) -> CornerRadiusOptions {
        .capsule(
            Capsule(
                minCornerRadius: minCornerRadius,
                maxCornerRadius: maxCornerRadius,
                style: style
            )
        )
    }

    public static let identity: CornerRadiusOptions = .rounded(cornerRadius: 0)

    @MainActor @preconcurrency
    public func apply(
        to view: UIView,
        height: CGFloat? = nil,
        masksToBounds: Bool = true
    ) {
        switch self {
        case .rounded(let options):
            options.apply(to: view, masksToBounds: masksToBounds)
        case .capsule(let options):
            options.apply(to: view, masksToBounds: masksToBounds)
        case .circle:
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *) {
                view.cornerConfiguration = .capsule()
            } else {
                view.layer.cornerRadius = cornerRadius(for: height ?? view.bounds.height)
            }
            #else
            view.layer.cornerRadius = cornerRadius(for: height ?? view.bounds.height)
            #endif
            view.layer.maskedCorners = mask
            view.layer.cornerCurve = style
            view.layer.masksToBounds = masksToBounds
        }
    }

    @MainActor @preconcurrency
    public func apply(
        to layer: CALayer,
        height: CGFloat,
        masksToBounds: Bool = true
    ) {
        switch self {
        case .rounded(let options):
            options.apply(to: layer, masksToBounds: masksToBounds)
        case .capsule(let options):
            options.apply(to: layer, masksToBounds: masksToBounds)
        case .circle:
            layer.cornerRadius = cornerRadius(for: height)
            layer.maskedCorners = mask
            layer.cornerCurve = style
            layer.masksToBounds = masksToBounds
        }
    }
}

extension CornerRadiusOptions.RoundedRectangle {

    @MainActor @preconcurrency
    public func apply(
        to view: UIView,
        masksToBounds: Bool = true
    ) {
        #if canImport(FoundationModels) // Xcode 26
        if #available(iOS 26.0, *) {
            let corner = isContainerConcentric
                ? UICornerRadius.containerConcentric(minimum: cornerRadius)
                : UICornerRadius.fixed(cornerRadius ?? 0)
            view.cornerConfiguration = UICornerConfiguration.corners(
                topLeftRadius: mask.contains(.layerMinXMinYCorner) ? corner : .fixed(0),
                topRightRadius: mask.contains(.layerMaxXMinYCorner) ? corner : .fixed(0),
                bottomLeftRadius: mask.contains(.layerMinXMaxYCorner) ? corner : .fixed(0),
                bottomRightRadius: mask.contains(.layerMaxXMaxYCorner) ? corner : .fixed(0)
            )
            view.layer.cornerCurve = style
            view.layer.masksToBounds = masksToBounds
        } else {
            apply(to: view.layer, masksToBounds: masksToBounds)
        }
        #else
        apply(to: view.layer, masksToBounds: masksToBounds)
        #endif
    }

    @MainActor @preconcurrency
    public func apply(
        to layer: CALayer,
        masksToBounds: Bool = true
    ) {
        layer.cornerRadius = cornerRadius ?? 0
        layer.maskedCorners = mask
        layer.cornerCurve = style
        layer.masksToBounds = masksToBounds
    }
}

extension CornerRadiusOptions.Capsule {

    @MainActor @preconcurrency
    public func apply(
        to view: UIView,
        masksToBounds: Bool = true
    ) {
        #if canImport(FoundationModels) // Xcode 26
        if #available(iOS 26.0, *) {
            view.cornerConfiguration = .capsule(maximumRadius: maxCornerRadius.map { Double($0) })
            view.layer.cornerCurve = style
        } else {
            apply(to: view.layer, masksToBounds: masksToBounds)
        }
        #else
        apply(to: view.layer, masksToBounds: masksToBounds)
        #endif
    }

    @MainActor @preconcurrency
    public func apply(
        to layer: CALayer,
        masksToBounds: Bool = true
    ) {
        layer.cornerRadius = cornerRadius(for: layer.bounds.height)
        layer.cornerCurve = style
    }

    public func cornerRadius(
        for height: CGFloat
    ) -> CGFloat {
        max(minCornerRadius ?? 0, min(height / 2, maxCornerRadius ?? height))
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
