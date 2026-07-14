//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@frozen
public enum CornerRadiusOptions: Equatable, Sendable, Shape {

    /// The corner radius of each corner of a rectangle.
    @frozen
    public struct CornerRadii: Equatable, Sendable {
        public var topLeft: CGFloat
        public var topRight: CGFloat
        public var bottomLeft: CGFloat
        public var bottomRight: CGFloat

        public init(
            topLeft: CGFloat,
            topRight: CGFloat,
            bottomLeft: CGFloat,
            bottomRight: CGFloat
        ) {
            self.topLeft = topLeft
            self.topRight = topRight
            self.bottomLeft = bottomLeft
            self.bottomRight = bottomRight
        }

        public init(_ cornerRadius: CGFloat) {
            self.init(
                topLeft: cornerRadius,
                topRight: cornerRadius,
                bottomLeft: cornerRadius,
                bottomRight: cornerRadius
            )
        }

        public static let zero = CornerRadii(0)

        public var isUniform: Bool {
            topLeft == topRight && topRight == bottomLeft && bottomLeft == bottomRight
        }

        /// The largest of the four radii, for use where only a single radius can be expressed.
        public var maximum: CGFloat {
            max(max(topLeft, topRight), max(bottomLeft, bottomRight))
        }

        /// Zeroes the radius of every corner not in `mask`.
        ///
        /// `CACornerMask` has no effect once per-corner radii are in use, so a mask is
        /// instead applied by zeroing the radii it excludes.
        public func masked(_ mask: CACornerMask) -> CornerRadii {
            CornerRadii(
                topLeft: mask.contains(.layerMinXMinYCorner) ? topLeft : 0,
                topRight: mask.contains(.layerMaxXMinYCorner) ? topRight : 0,
                bottomLeft: mask.contains(.layerMinXMaxYCorner) ? bottomLeft : 0,
                bottomRight: mask.contains(.layerMaxXMaxYCorner) ? bottomRight : 0
            )
        }

        public func clamped(to size: CGSize) -> CornerRadii {
            let limit = min(size.width / 2, size.height / 2)
            return CornerRadii(
                topLeft: min(topLeft, limit),
                topRight: min(topRight, limit),
                bottomLeft: min(bottomLeft, limit),
                bottomRight: min(bottomRight, limit)
            )
        }
    }

    @frozen
    public struct RoundedRectangle: Equatable, Sendable, Shape {
        public var cornerRadii: CornerRadii?
        public var mask: CACornerMask
        public var style: CALayerCornerCurve
        public var isContainerConcentric: Bool

        /// The uniform corner radius.
        ///
        /// Reading returns the largest of the four radii, for the callers—such as
        /// `UISheetPresentationController.preferredCornerRadius`—that can only express one.
        public var cornerRadius: CGFloat? {
            get { cornerRadii?.maximum }
            set { cornerRadii = newValue.map { CornerRadii($0) } }
        }

        private init(
            cornerRadii: CornerRadii?,
            mask: CACornerMask,
            style: CALayerCornerCurve,
            isContainerConcentric: Bool = false
        ) {
            self.cornerRadii = cornerRadii
            self.mask = mask
            self.style = style
            self.isContainerConcentric = isContainerConcentric
        }

        /// The radii as rendered: masked, and clamped to `size` when one is known.
        public func resolvedCornerRadii(for size: CGSize? = nil) -> CornerRadii {
            let cornerRadii = (cornerRadii ?? .zero).masked(mask)
            guard let size else { return cornerRadii }
            return cornerRadii.clamped(to: size)
        }

        public nonisolated func path(in rect: CGRect) -> Path {
            if isContainerConcentric, #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                return SwiftUI.ContainerRelativeShape().path(in: rect)
            }
            let cornerRadii = resolvedCornerRadii()
            if cornerRadii.isUniform {
                return SwiftUI.RoundedRectangle(
                    cornerRadius: cornerRadii.topLeft,
                    style: style.toSwiftUI()
                ).path(in: rect)
            }
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadii.topLeft,
                    bottomLeadingRadius: cornerRadii.bottomLeft,
                    bottomTrailingRadius: cornerRadii.bottomRight,
                    topTrailingRadius: cornerRadii.topRight,
                    style: style.toSwiftUI()
                ).path(in: rect)
            }
            return RoundedCornersRectangle(
                topLeadingRadius: cornerRadii.topLeft,
                bottomLeadingRadius: cornerRadii.bottomLeft,
                bottomTrailingRadius: cornerRadii.bottomRight,
                topTrailingRadius: cornerRadii.topRight,
                style: style.toSwiftUI()
            ).path(in: rect)
        }

        public static let identity: RoundedRectangle = .rounded(cornerRadius: 0)

        public static func rounded(
            cornerRadius: CGFloat,
            mask: CACornerMask,
            style: CALayerCornerCurve
        ) -> RoundedRectangle {
            RoundedRectangle(
                cornerRadii: CornerRadii(cornerRadius),
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

        public static func rounded(
            cornerRadii: CornerRadii,
            mask: CACornerMask = .all,
            style: CALayerCornerCurve = .continuous
        ) -> RoundedRectangle {
            RoundedRectangle(
                cornerRadii: cornerRadii,
                mask: mask,
                style: style
            )
        }

        public static func rounded(
            topLeft: CGFloat,
            topRight: CGFloat,
            bottomLeft: CGFloat,
            bottomRight: CGFloat,
            style: CALayerCornerCurve = .continuous
        ) -> RoundedRectangle {
            .rounded(
                cornerRadii: CornerRadii(
                    topLeft: topLeft,
                    topRight: topRight,
                    bottomLeft: bottomLeft,
                    bottomRight: bottomRight
                ),
                style: style
            )
        }

        @MainActor @preconcurrency
        public static func screen(
            min: CGFloat = 12
        ) -> RoundedRectangle {
            let cornerRadius = UIScreen.main.displayCornerRadius
            return RoundedRectangle(
                cornerRadii: CornerRadii(max(min, cornerRadius)),
                mask: .all,
                style: min > cornerRadius ? .continuous : .circular,
                isContainerConcentric: false
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
                cornerRadii: cornerRadius.map { CornerRadii($0) },
                mask: mask,
                style: style,
                isContainerConcentric: true
            )
        }
    }

    @frozen
    public struct Capsule: Equatable, Sendable, Shape {
        public var minCornerRadius: CGFloat?
        public var maxCornerRadius: CGFloat?
        public var style: CALayerCornerCurve

        public nonisolated func path(in rect: CGRect) -> Path {
            let cornerRadius = cornerRadius(for: rect.size)
            if let minCornerRadius, minCornerRadius > cornerRadius {
                return SwiftUI.RoundedRectangle(cornerRadius: minCornerRadius, style: style.toSwiftUI()).path(in: rect)
            }
            if let maxCornerRadius, maxCornerRadius < cornerRadius {
                return SwiftUI.RoundedRectangle(cornerRadius: maxCornerRadius, style: style.toSwiftUI()).path(in: rect)
            }
            return SwiftUI.Capsule(style: style.toSwiftUI()).path(in: rect)
        }
    }

    case rounded(RoundedRectangle)
    case circle
    case capsule(Capsule)

    public nonisolated func path(in rect: CGRect) -> Path {
        switch self {
        case .rounded(let options):
            return options.path(in: rect)
        case .circle:
            return Circle().path(in: rect)
        case .capsule(let options):
            return options.path(in: rect)
        }
    }

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

    public func cornerRadius(for size: CGSize? = nil) -> CGFloat {
        switch self {
        case .rounded(let options):
            return options.cornerRadius ?? 0
        case .circle:
            guard let size else { return 0 }
            return min(size.width / 2, size.height / 2)
        case .capsule(let options):
            return options.cornerRadius(for: size)
        }
    }

    public static func rounded(
        cornerRadius: CGFloat,
        style: CALayerCornerCurve = .continuous
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

    public static func rounded(
        cornerRadii: CornerRadii,
        mask: CACornerMask = .all,
        style: CALayerCornerCurve = .continuous
    ) -> CornerRadiusOptions {
        .rounded(
            .rounded(
                cornerRadii: cornerRadii,
                mask: mask,
                style: style
            )
        )
    }

    public static func rounded(
        topLeft: CGFloat,
        topRight: CGFloat,
        bottomLeft: CGFloat,
        bottomRight: CGFloat,
        style: CALayerCornerCurve = .continuous
    ) -> CornerRadiusOptions {
        .rounded(
            .rounded(
                topLeft: topLeft,
                topRight: topRight,
                bottomLeft: bottomLeft,
                bottomRight: bottomRight,
                style: style
            )
        )
    }

    public static func containerConcentric(
        minimum cornerRadius: CGFloat? = nil,
        style: CALayerCornerCurve = .continuous
    ) -> CornerRadiusOptions {
        containerConcentric(
            minimum: cornerRadius,
            mask: .all,
            style: style
        )
    }

    public static func containerConcentric(
        minimum cornerRadius: CGFloat? = nil,
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
        size: CGSize? = nil,
        masksToBounds: Bool = true
    ) {
        switch self {
        case .rounded(let options):
            options.apply(to: view, size: size, masksToBounds: masksToBounds)
        case .capsule(let options):
            options.apply(to: view, size: size, masksToBounds: masksToBounds)
        case .circle:
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *) {
                view.cornerConfiguration = makeCornerConfiguration()
            }
            #endif
            apply(to: view.layer, size: size, masksToBounds: masksToBounds)
        }
    }

    @MainActor @preconcurrency
    public func apply(
        to layer: CALayer,
        size: CGSize? = nil,
        masksToBounds: Bool = true
    ) {
        switch self {
        case .rounded(let options):
            options.apply(to: layer, size: size, masksToBounds: masksToBounds)
        case .capsule(let options):
            options.apply(to: layer, size: size, masksToBounds: masksToBounds)
        case .circle:
            let cornerRadius = cornerRadius(for: size ?? layer.bounds.size)
            layer.cornerRadius = cornerRadius
            layer.maskedCorners = mask
            layer.cornerCurve = style
            layer.masksToBounds = masksToBounds
            if layer.usesCornerRadii {
                layer.setCornerRadii(CornerRadii(cornerRadius))
            }
        }
    }

    #if canImport(FoundationModels) // Xcode 26
    @available(iOS 26.0, *)
    func makeCornerConfiguration() -> UICornerConfiguration {
        switch self {
        case .rounded(let roundedRectangle):
            return roundedRectangle.makeCornerConfiguration()
        case .circle:
            return .capsule()
        case .capsule(let capsule):
            return capsule.makeCornerConfiguration()
        }
    }
    #endif
}

extension CornerRadiusOptions.RoundedRectangle {

    @MainActor @preconcurrency
    public func apply(
        to view: UIView,
        size: CGSize? = nil,
        masksToBounds: Bool = true
    ) {
        #if canImport(FoundationModels) // Xcode 26
        if #available(iOS 26.0, *) {
            // A radius per corner has a public API on a `UIView`, so the private
            // property on its layer is left alone.
            view.cornerConfiguration = makeCornerConfiguration()
            let cornerRadii = resolvedCornerRadii(for: size)
            view.layer.cornerRadius = cornerRadii.maximum
            view.layer.maskedCorners = mask
            view.layer.cornerCurve = style
            view.layer.masksToBounds = masksToBounds
            return
        }
        #endif
        apply(to: view.layer, size: size, masksToBounds: masksToBounds)
    }

    @MainActor @preconcurrency
    public func apply(
        to layer: CALayer,
        size: CGSize? = nil,
        masksToBounds: Bool = true
    ) {
        let cornerRadii = resolvedCornerRadii(for: size)
        layer.cornerCurve = style
        layer.masksToBounds = masksToBounds

        // A uniform radius on a layer that has never been given a radius per corner.
        if cornerRadii.isUniform, !layer.usesCornerRadii {
            layer.cornerRadius = cornerRadii.topLeft
            layer.maskedCorners = mask
            return
        }

        // `cornerRadius` no longer governs rendering, but is kept in sync so that the
        // drop shadow path, the dimming view and the transitions, all of which read a
        // single radius back off the layer, continue to see a usable value.
        layer.cornerRadius = cornerRadii.maximum

        guard CALayer.supportsCornerRadii else {
            // iOS 15 and earlier. Degrade to the largest of the four radii.
            layer.maskedCorners = mask
            return
        }
        layer.setCornerRadii(cornerRadii)
    }

    #if canImport(FoundationModels) // Xcode 26
    @available(iOS 26.0, *)
    func makeCornerConfiguration() -> UICornerConfiguration {
        let cornerRadii = resolvedCornerRadii()
        func corner(
            _ cornerRadius: CGFloat,
            _ isMasked: Bool
        ) -> UICornerRadius? {
            guard isMasked else { return nil }
            if isContainerConcentric {
                return .containerConcentric(minimum: self.cornerRadii == nil ? nil : cornerRadius)
            }
            return self.cornerRadii == nil ? nil : .fixed(cornerRadius)
        }
        return UICornerConfiguration.corners(
            topLeftRadius: corner(cornerRadii.topLeft, mask.contains(.layerMinXMinYCorner)),
            topRightRadius: corner(cornerRadii.topRight, mask.contains(.layerMaxXMinYCorner)),
            bottomLeftRadius: corner(cornerRadii.bottomLeft, mask.contains(.layerMinXMaxYCorner)),
            bottomRightRadius: corner(cornerRadii.bottomRight, mask.contains(.layerMaxXMaxYCorner))
        )
    }
    #endif
}

extension CornerRadiusOptions.Capsule {

    @MainActor @preconcurrency
    public func apply(
        to view: UIView,
        size: CGSize? = nil,
        masksToBounds: Bool = true
    ) {
        #if canImport(FoundationModels) // Xcode 26
        if #available(iOS 26.0, *) {
            view.cornerConfiguration = makeCornerConfiguration()
        }
        #endif
        apply(to: view.layer, size: size, masksToBounds: masksToBounds)
    }

    @MainActor @preconcurrency
    public func apply(
        to layer: CALayer,
        size: CGSize? = nil,
        masksToBounds: Bool = true
    ) {
        let cornerRadius = cornerRadius(for: size ?? layer.bounds.size)
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = style
        layer.masksToBounds = masksToBounds
        if layer.usesCornerRadii {
            layer.setCornerRadii(CornerRadiusOptions.CornerRadii(cornerRadius))
        }
    }

    public func cornerRadius(
        for size: CGSize? = nil
    ) -> CGFloat {
        if let size {
            let idealCornerRadius = min(size.width / 2, size.height / 2)
            return max(min(minCornerRadius ?? 0, idealCornerRadius), min(maxCornerRadius ?? .infinity, idealCornerRadius))
        }
        return minCornerRadius ?? 0
    }

    #if canImport(FoundationModels) // Xcode 26
    @available(iOS 26.0, *)
    func makeCornerConfiguration() -> UICornerConfiguration {
        return UICornerConfiguration.capsule(maximumRadius: maxCornerRadius.map { Double($0) })
    }
    #endif
}

extension CACornerMask {
    public static let all: CACornerMask = [
        .layerMaxXMaxYCorner,
        .layerMaxXMinYCorner,
        .layerMinXMaxYCorner,
        .layerMinXMinYCorner
    ]

    public static let topLeft: CACornerMask = .layerMinXMinYCorner

    public static let topRight: CACornerMask = .layerMaxXMinYCorner

    public static let bottomLeft: CACornerMask = .layerMinXMaxYCorner

    public static let bottomRight: CACornerMask = .layerMaxXMaxYCorner
}

extension CALayerCornerCurve {

    func toSwiftUI() -> RoundedCornerStyle {
        switch self {
        case .circular:
            return .circular
        case .continuous:
            return .continuous
        default:
            return .circular
        }
    }
}

#if canImport(FoundationModels) // Xcode 26
@available(iOS 26.0, *)
extension UICornerConfiguration {

    static var identity: UICornerConfiguration {
        UICornerConfiguration.corners(topLeftRadius: .fixed(0), topRightRadius: .fixed(0), bottomLeftRadius: .fixed(0), bottomRightRadius: .fixed(0))
    }
}
#endif

extension UIView {

    func applyCornerRadius(from source: UIView) {
        #if canImport(FoundationModels) // Xcode 26
        if #available(iOS 26.0, *) {
            cornerConfiguration = source.cornerConfiguration
        }
        #endif
        layer.cornerRadius = source.layer.cornerRadius
        layer.maskedCorners = source.layer.maskedCorners
        layer.cornerCurve = source.layer.cornerCurve
        layer.masksToBounds = source.layer.masksToBounds
        if source.layer.usesCornerRadii, let cornerRadii = source.layer.cornerRadii() {
            layer.setCornerRadii(cornerRadii)
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct CornerRadiusOptions_Previews: PreviewProvider {

    struct Preview: View {
        var color: Color = .blue
        var options: CornerRadiusOptions

        class CornerRadiusView: UIView {
            var options: CornerRadiusOptions = .identity {
                didSet {
                    guard oldValue != options else { return }
                    options.apply(to: self)
                }
            }

            override func layoutSubviews() {
                super.layoutSubviews()
                if #unavailable(iOS 26.0) {
                    options.apply(to: self)
                }
            }
        }

        var body: some View {
            ViewRepresentableAdapter {
                let uiView = CornerRadiusView()
                uiView.options = options
                uiView.backgroundColor = color.toUIColor()
                return uiView
            }

            options
                .fill(color)
        }
    }

    static var previews: some View {
        VStack {
            VStack {
                Preview(options: .identity)
                    .frame(width: 50, height: 50)
            }

            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                HStack {
                    ContainerRelativeShape()
                        .fill(Color.blue)
                        .frame(width: 100, height: 50)
                        .containerShape(RoundedRectangle(cornerRadius: 12))

                    CornerRadiusOptions.containerConcentric()
                        .fill(Color.blue)
                        .frame(width: 100, height: 50)
                        .containerShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            HStack {
                VStack {
                    Preview(options: .rounded(cornerRadius: 12))
                        .frame(width: 100, height: 50)
                }

                VStack {
                    Preview(options: .containerConcentric(minimum: 12))
                        .frame(width: 100, height: 50)
                }

                VStack {
                    Preview(
                        options: .rounded(
                            cornerRadius: 12,
                            mask: [.topLeft, .bottomRight],
                            style: .circular
                        )
                    )
                    .frame(width: 100, height: 50)
                }

                VStack {
                    Preview(
                        options: .rounded(
                            topLeft: 24,
                            topRight: 24,
                            bottomLeft: 4,
                            bottomRight: 4
                        )
                    )
                    .frame(width: 100, height: 50)
                }
            }

            HStack {
                VStack {
                    Preview(options: .capsule)
                        .frame(width: 100, height: 30)
                }

                VStack {
                    Preview(options: .circle)
                        .frame(width: 30, height: 30)
                }
            }

            ZStack {
                VStack {
                    Preview(
                        color: .red,
                        options: .rounded(cornerRadius: 16, style: .circular)
                    )
                    .frame(width: 100, height: 50)
                }

                VStack {
                    Preview(
                        options: .rounded(cornerRadius: 16, style: .continuous)
                    )
                    .frame(width: 100, height: 50)
                }
            }
        }
    }
}

#endif
