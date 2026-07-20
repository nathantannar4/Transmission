//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import Engine
import UIKit
import SwiftUI

@frozen
public struct CornerRadiusOptions: Equatable, Sendable {

    @frozen
    public struct CornerRadii: Equatable, Sendable {

        public var topLeading: CGFloat
        public var bottomLeading: CGFloat
        public var bottomTrailing: CGFloat
        public var topTrailing: CGFloat

        public var uniformCornerRadius: CGFloat {
            max(max(topLeading, topTrailing), max(bottomLeading, bottomTrailing))
        }

        public init(
            topLeading: CGFloat,
            bottomLeading: CGFloat,
            bottomTrailing: CGFloat,
            topTrailing: CGFloat
        ) {
            self.topLeading = topLeading
            self.topTrailing = topTrailing
            self.bottomLeading = bottomLeading
            self.bottomTrailing = bottomTrailing
        }

        public init(cornerRadius: CGFloat) {
            self.init(
                topLeading: cornerRadius,
                bottomLeading: cornerRadius,
                bottomTrailing: cornerRadius,
                topTrailing: cornerRadius,
            )
        }

        public func isUniform(mask: CornerMask) -> Bool {
            var reference: CGFloat?
            if mask.contains(.topLeading) {
                reference = topLeading
            }
            if mask.contains(.bottomLeading) {
                if let reference, bottomLeading != reference {
                    return false
                }
                reference = bottomLeading
            }
            if mask.contains(.bottomTrailing) {
                if let reference, bottomTrailing != reference {
                    return false
                }
                reference = bottomTrailing
            }
            if mask.contains(.topTrailing) {
                if let reference, topTrailing != reference {
                    return false
                }
            }
            return true
        }

        public func resolved(for size: CGSize? = nil, mask: CornerMask) -> CornerRadii {
            let masked = CornerRadii(
                topLeading: mask.contains(.topLeading) ? topLeading : 0,
                bottomLeading: mask.contains(.bottomLeading) ? bottomLeading : 0,
                bottomTrailing: mask.contains(.bottomTrailing) ? bottomTrailing : 0,
                topTrailing: mask.contains(.topTrailing) ? topTrailing : 0,
            )
            guard let size else { return masked }
            let limit = min(size.width / 2, size.height / 2)
            let bounded = CornerRadii(
                topLeading: min(masked.topLeading, limit),
                bottomLeading: min(masked.bottomLeading, limit),
                bottomTrailing: min(masked.bottomTrailing, limit),
                topTrailing: min(masked.topTrailing, limit),
            )
            return bounded
        }
    }

    @frozen
    public struct CornerCurve: Equatable, Sendable {

        @usableFromInline
        enum Style: Equatable, Sendable {
            case circular
            case continuous
        }
        @usableFromInline
        var style: Style

        private init(style: Style) {
            self.style = style
        }

        public init?(
            curve: CALayerCornerCurve
        ) {
            if curve == .circular {
                self = .circular
            } else if curve == .continuous {
                self = .continuous
            } else {
                return nil
            }
        }

        public static let circular = CornerCurve(style: .circular)

        public static let continuous = CornerCurve(style: .continuous)
    }

    @frozen
    public struct CornerMask: OptionSet, Sendable {

        public var rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public init(
            mask: CACornerMask,
            layoutDirectionIsLeftToRight: Bool = true
        ) {
            self.rawValue = 0
            if mask.contains(.topLeft) {
                formUnion(layoutDirectionIsLeftToRight ? .topLeading : .topTrailing)
            }
            if mask.contains(.bottomLeft) {
                formUnion(layoutDirectionIsLeftToRight ? .bottomLeading : .bottomTrailing)
            }
            if mask.contains(.bottomRight) {
                formUnion(layoutDirectionIsLeftToRight ? .bottomTrailing : .bottomLeading)
            }
            if mask.contains(.topRight) {
                formUnion(layoutDirectionIsLeftToRight ? .topTrailing : .topLeading)
            }
        }

        public static let topLeading = CornerMask(rawValue: 1 << 0)

        public static let bottomLeading = CornerMask(rawValue: 1 << 1)

        public static let bottomTrailing = CornerMask(rawValue: 1 << 2)

        public static let topTrailing = CornerMask(rawValue: 1 << 3)

        public static let all = CornerMask(rawValue: UInt8.max)

        public static let top: CornerMask = [.topLeading, .topTrailing]

        public static let bottom: CornerMask = [.bottomLeading, .bottomTrailing]

        public static let leading: CornerMask = [.topLeading, .bottomLeading]

        public static let trailing: CornerMask = [.topTrailing, .bottomTrailing]
    }

    @frozen
    public struct RoundedRectangle: Equatable, Sendable {

        public var cornerRadii: CornerRadii?
        public var mask: CornerMask
        public var style: CornerCurve
        public var isContainerConcentric: Bool = false

        public static let identity: RoundedRectangle = .rounded(cornerRadius: 0)

        public static func rounded(
            cornerRadius: CGFloat,
            mask: CornerMask = .all,
            style: CornerCurve = .continuous
        ) -> RoundedRectangle {
            RoundedRectangle(
                cornerRadii: CornerRadii(cornerRadius: cornerRadius),
                mask: mask,
                style: style
            )
        }

        @available(iOS 16.0, *)
        public static func unevenRounded(
            cornerRadii: CornerRadii,
            style: CornerCurve = .continuous
        ) -> RoundedRectangle {
            RoundedRectangle(
                cornerRadii: cornerRadii,
                mask: .all,
                style: style
            )
        }

        @available(iOS 16.0, *)
        public static func unevenRounded(
            topLeading: CGFloat,
            bottomLeading: CGFloat,
            bottomTrailing: CGFloat,
            topTrailing: CGFloat,
            style: CornerCurve = .continuous
        ) -> RoundedRectangle {
            .unevenRounded(
                cornerRadii: CornerRadii(
                    topLeading: topLeading,
                    bottomLeading: bottomLeading,
                    bottomTrailing: bottomTrailing,
                    topTrailing: topTrailing,
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
                cornerRadii: CornerRadii(cornerRadius: max(min, cornerRadius)),
                mask: .all,
                style: min > cornerRadius ? .continuous : .circular,
                isContainerConcentric: false
            )
        }

        public static func containerConcentric(
            minimum cornerRadius: CGFloat?,
            mask: CornerMask = .all,
            style: CornerCurve = .continuous
        ) -> RoundedRectangle {
            RoundedRectangle(
                cornerRadii: cornerRadius.map { CornerRadii(cornerRadius: $0) },
                mask: mask,
                style: style,
                isContainerConcentric: true
            )
        }
    }

    @frozen
    public struct Circle: Equatable, Sendable {
    }

    @frozen
    public struct Capsule: Equatable, Sendable {
        public var minCornerRadius: CGFloat?
        public var maxCornerRadius: CGFloat?
        public var style: CornerCurve
    }

    @usableFromInline
    enum Storage: Equatable, Sendable {
        case rounded(RoundedRectangle)
        case circle(Circle)
        case capsule(Capsule)
    }
    @usableFromInline
    var storage: Storage

    public var mask: CornerMask {
        switch storage {
        case .rounded(let options):
            return options.mask
        case .circle, .capsule:
            return .all
        }
    }

    public var style: CornerCurve {
        switch storage {
        case .rounded(let options):
            return options.style
        case .circle:
            return .circular
        case .capsule(let options):
            return options.style
        }
    }

    public func cornerRadius(for size: CGSize? = nil) -> CGFloat {
        switch storage {
        case .rounded(let options):
            return options.cornerRadius(for: size)
        case .circle(let options):
            return options.cornerRadius(for: size)
        case .capsule(let options):
            return options.cornerRadius(for: size)
        }
    }

    public static func rounded(
        cornerRadius: CGFloat,
        mask: CornerMask = .all,
        style: CornerCurve = .continuous
    ) -> CornerRadiusOptions {
        CornerRadiusOptions(
            storage: .rounded(
                .rounded(
                    cornerRadius: cornerRadius,
                    mask: mask,
                    style: style
                )
            )
        )
    }

    @available(iOS 16.0, *)
    public static func unevenRounded(
        cornerRadii: CornerRadii,
        style: CornerCurve = .continuous
    ) -> CornerRadiusOptions {
        CornerRadiusOptions(
            storage: .rounded(
                .unevenRounded(
                    cornerRadii: cornerRadii,
                    style: style
                )
            )
        )
    }

    @available(iOS 16.0, *)
    public static func unevenRounded(
        topLeading: CGFloat,
        bottomLeading: CGFloat,
        bottomTrailing: CGFloat,
        topTrailing: CGFloat,
        style: CornerCurve = .continuous
    ) -> CornerRadiusOptions {
        .unevenRounded(
            cornerRadii: CornerRadii(
                topLeading: topLeading,
                bottomLeading: bottomLeading,
                bottomTrailing: bottomTrailing,
                topTrailing: topTrailing
            ),
            style: style
        )
    }

    @MainActor @preconcurrency
    public static func screen(
        min: CGFloat = 12
    ) -> CornerRadiusOptions {
        return CornerRadiusOptions(
            storage: .rounded(
                .screen(
                    min: min
                )
            )
        )
    }

    public static func containerConcentric(
        minimum cornerRadius: CGFloat? = nil,
        mask: CornerMask = .all,
        style: CornerCurve = .continuous
    ) -> CornerRadiusOptions {
        CornerRadiusOptions(
            storage: .rounded(
                .containerConcentric(
                    minimum: cornerRadius,
                    mask: mask,
                    style: style
                )
            )
        )
    }

    public static var capsule: CornerRadiusOptions {
        .capsule()
    }

    public static func capsule(
        minCornerRadius: CGFloat? = nil,
        maxCornerRadius: CGFloat? = nil,
        style: CornerCurve = .circular
    ) -> CornerRadiusOptions {
        CornerRadiusOptions(
            storage: .capsule(
                Capsule(
                    minCornerRadius: minCornerRadius,
                    maxCornerRadius: maxCornerRadius,
                    style: style
                )
            )
        )
    }

    public static var circle: CornerRadiusOptions {
        CornerRadiusOptions(
            storage: .circle(Circle())
        )
    }

    public static let identity: CornerRadiusOptions = .rounded(cornerRadius: 0)

}

extension CornerRadiusOptions: Shape, InsettableShape {

    public var animatableData: AnyAnimatableData {
        get {
            switch storage {
            case .rounded(let options):
                return AnyAnimatableData(options.animatableData)
            case .circle:
                return AnyAnimatableData(EmptyAnimatableData())
            case .capsule(let options):
                return AnyAnimatableData(options.animatableData)
            }
        }
        set {
            switch storage {
            case .rounded(var options):
                if let newValue = newValue.value(as: RoundedRectangle.AnimatableData.self) {
                    options.animatableData = newValue
                    storage = .rounded(options)
                }
            case .circle:
                break
            case .capsule(var options):
                if let newValue = newValue.value(as: Capsule.AnimatableData.self) {
                    options.animatableData = newValue
                    storage = .capsule(options)
                }
            }
        }
    }

    public nonisolated func path(in rect: CGRect) -> Path {
        switch storage {
        case .rounded(let options):
            return options.path(in: rect)
        case .circle(let options):
            return options.path(in: rect)
        case .capsule(let options):
            return options.path(in: rect)
        }
    }

    public nonisolated func inset(by amount: CGFloat) -> Engine.AnyShape {
        switch storage {
        case .rounded(let options):
            return options.inset(by: amount)
        case .circle(let options):
            return AnyShape(shape: options.inset(by: amount))
        case .capsule(let options):
            return AnyShape(shape: options.inset(by: amount))
        }
    }
}

extension CornerRadiusOptions.RoundedRectangle: Shape, InsettableShape {

    public typealias AnimatableData = AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>
    public var animatableData: AnimatableData {
        get {
            let cornerRadii = cornerRadii?.resolved(mask: mask) ?? CornerRadiusOptions.CornerRadii(cornerRadius: 0)
            return AnimatablePair(
                AnimatablePair(
                    cornerRadii.topLeading,
                    cornerRadii.bottomLeading
                ),
                AnimatablePair(
                    cornerRadii.bottomTrailing,
                    cornerRadii.topTrailing
                )
            )
        }
        set {
            cornerRadii = CornerRadiusOptions.CornerRadii(
                topLeading: newValue.first.first,
                bottomLeading: newValue.first.second,
                bottomTrailing: newValue.second.first,
                topTrailing: newValue.second.second,
            )
        }
    }

    public nonisolated func path(in rect: CGRect) -> Path {
        if isContainerConcentric, cornerRadii == nil, #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            return SwiftUI.ContainerRelativeShape().path(in: rect)
        }
        let cornerRadii = cornerRadii?.resolved(for: rect.size, mask: mask) ?? CornerRadiusOptions.CornerRadii(cornerRadius: 0)
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return SwiftUI.UnevenRoundedRectangle(
                topLeadingRadius: cornerRadii.topLeading,
                bottomLeadingRadius: cornerRadii.bottomLeading,
                bottomTrailingRadius: cornerRadii.bottomTrailing,
                topTrailingRadius: cornerRadii.topTrailing,
                style: style.toSwiftUI()
            ).path(in: rect)
        }
        return Engine.RoundedCornersRectangle(
            topLeadingRadius: cornerRadii.topLeading,
            bottomLeadingRadius: cornerRadii.bottomLeading,
            bottomTrailingRadius: cornerRadii.bottomTrailing,
            topTrailingRadius: cornerRadii.topTrailing,
            style: style.toSwiftUI()
        ).path(in: rect)
    }

    public nonisolated func inset(by amount: CGFloat) -> Engine.AnyShape {
        if isContainerConcentric, cornerRadii == nil, #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            return AnyShape(shape: SwiftUI.ContainerRelativeShape().inset(by: amount))
        }
        let cornerRadii = cornerRadii?.resolved(mask: mask) ?? CornerRadiusOptions.CornerRadii(cornerRadius: 0)
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return AnyShape(
                shape: SwiftUI.UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadii.topLeading,
                    bottomLeadingRadius: cornerRadii.bottomLeading,
                    bottomTrailingRadius: cornerRadii.bottomTrailing,
                    topTrailingRadius: cornerRadii.topTrailing,
                    style: style.toSwiftUI()
                ).inset(by: amount)
            )
        }
        return AnyShape(
            shape: Engine.RoundedCornersRectangle(
                topLeadingRadius: cornerRadii.topLeading,
                bottomLeadingRadius: cornerRadii.bottomLeading,
                bottomTrailingRadius: cornerRadii.bottomTrailing,
                topTrailingRadius: cornerRadii.topTrailing,
                style: style.toSwiftUI()
            )
            .inset(by: amount)
        )
    }
}

extension CornerRadiusOptions.Capsule: Shape, InsettableShape {

    public var animatableData: CGFloat {
        get { maxCornerRadius ?? 0 }
        set { maxCornerRadius = newValue }
    }

    public nonisolated func path(in rect: CGRect) -> Path {
        return CapsuleRoundedRectangle(
            maxCornerRadius: maxCornerRadius,
            style: style.toSwiftUI()
        ).path(in: rect)
    }

    public nonisolated func inset(by amount: CGFloat) -> CapsuleRoundedRectangle.InsetShape {
        return CapsuleRoundedRectangle(
            maxCornerRadius: maxCornerRadius,
            style: style.toSwiftUI()
        ).inset(by: amount)
    }
}

extension CornerRadiusOptions.Circle: Shape, InsettableShape {

    public nonisolated func path(in rect: CGRect) -> Path {
        return Circle().path(in: rect)
    }

    public nonisolated func inset(by amount: CGFloat) -> Circle.InsetShape {
        return Circle().inset(by: amount)
    }
}

#if canImport(FoundationModels) // Xcode 26
extension CornerRadiusOptions: RoundedRectangularShape {

    @available(iOS 26.0, *)
    public func corners(in size: CGSize?) -> Corners? {
        switch storage {
        case .rounded(let options):
            return options.corners(in: size)
        case .circle:
            let radius = cornerRadius(for: size)
            return RoundedRectangularShapeCorners(all: .fixed(radius))
        case .capsule(let options):
            return options.corners(in: size)
        }
    }
}

extension CornerRadiusOptions.RoundedRectangle: RoundedRectangularShape {

    @available(iOS 26.0, *)
    public func corners(in size: CGSize?) -> Corners? {
        let cornerRadii = cornerRadii?.resolved(for: size, mask: mask) ?? CornerRadiusOptions.CornerRadii(cornerRadius: 0)
        return Corners(
            topLeading: isContainerConcentric ? .concentric(minimum: .fixed(cornerRadii.topLeading)) : .fixed(cornerRadii.topLeading),
            topTrailing: isContainerConcentric ? .concentric(minimum: .fixed(cornerRadii.topTrailing)) : .fixed(cornerRadii.topTrailing),
            bottomLeading: isContainerConcentric ? .concentric(minimum: .fixed(cornerRadii.bottomLeading)) : .fixed(cornerRadii.bottomLeading),
            bottomTrailing: isContainerConcentric ? .concentric(minimum: .fixed(cornerRadii.bottomTrailing)) : .fixed(cornerRadii.bottomTrailing)
        )
    }
}

extension CornerRadiusOptions.Capsule: RoundedRectangularShape {

    @available(iOS 26.0, *)
    public func corners(in size: CGSize?) -> Corners? {
        let cornerRadius = cornerRadius(for: size)
        return Corners(all: .fixed(cornerRadius))
    }
}

extension CornerRadiusOptions.Circle: RoundedRectangularShape {

    @available(iOS 26.0, *)
    public func corners(in size: CGSize?) -> Corners? {
        return Circle().corners(in: size)
    }
}
#endif

extension CornerRadiusOptions {

    @MainActor @preconcurrency
    public func apply(
        to view: UIView,
        size: CGSize? = nil,
        masksToBounds: Bool = true
    ) {
        switch storage {
        case .rounded(let options):
            options.apply(
                to: view,
                size: size,
                masksToBounds: masksToBounds
            )

        case .circle(let options):
            options.apply(
                to: view,
                size: size,
                masksToBounds: masksToBounds
            )

        case .capsule(let options):
            options.apply(
                to: view,
                size: size,
                masksToBounds: masksToBounds
            )
        }
    }

    @MainActor @preconcurrency
    public func apply(
        to layer: CALayer,
        size: CGSize? = nil,
        masksToBounds: Bool = true,
        useCornerRadii: Bool = true,
        layoutDirectionIsLeftToRight: Bool = true
    ) {
        switch storage {
        case .rounded(let options):
            options.apply(
                to: layer,
                size: size,
                masksToBounds: masksToBounds,
                useCornerRadii: useCornerRadii,
                layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight
            )
        case .capsule(let options):
            options.apply(
                to: layer,
                size: size,
                masksToBounds: masksToBounds,
                useCornerRadii: useCornerRadii
            )
        case .circle(let options):
            options.apply(
                to: layer,
                size: size,
                masksToBounds: masksToBounds,
                useCornerRadii: useCornerRadii
            )
        }
    }

    #if canImport(FoundationModels) // Xcode 26
    @available(iOS 26.0, *)
    public func cornerConfiguration(
        size: CGSize? = nil,
        layoutDirectionIsLeftToRight: Bool = true
    ) -> UICornerConfiguration {
        switch storage {
        case .rounded(let options):
            return options.cornerConfiguration(
                size: size,
                layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight
            )
        case .circle(let options):
            return options.cornerConfiguration()
        case .capsule(let options):
            return options.cornerConfiguration(
                size: size,
                layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight
            )
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
        let layoutDirectionIsLeftToRight = view.effectiveUserInterfaceLayoutDirection == .leftToRight
        #if canImport(FoundationModels) // Xcode 26
        if #available(iOS 26.0, *) {
            view.cornerConfiguration = cornerConfiguration(
                size: size ?? view.bounds.size,
                layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight
            )
        }
        #endif
        apply(
            to: view.layer,
            size: size,
            masksToBounds: masksToBounds,
            useCornerRadii: {
                #if canImport(FoundationModels) // Xcode 26
                if #available(iOS 26.0, *) {
                    // `cornerRadii` managed by `cornerConfiguration`
                    return false
                }
                #endif
                return view.layer.hasCornerRadii || cornerRadii?.isUniform(mask: mask) == false
            }(),
            layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight
        )
    }

    @MainActor @preconcurrency
    public func apply(
        to layer: CALayer,
        size: CGSize? = nil,
        masksToBounds: Bool = true,
        useCornerRadii: Bool = true,
        layoutDirectionIsLeftToRight: Bool = true
    ) {
        if #available(iOS 16.0, *), useCornerRadii {
            layer.fixCornerRadiiAnimation()
        }
        let cornerRadii = cornerRadii?.resolved(for: size, mask: mask)
        layer.cornerRadius = cornerRadii?.uniformCornerRadius ?? 0
        layer.cornerCurve = style.toCoreAnimation()
        layer.maskedCorners = mask.toCoreAnimation(
            layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight
        )
        layer.masksToBounds = masksToBounds
        if #available(iOS 16.0, *), useCornerRadii {
            layer.cornerRadii = cornerRadii
        }
    }

    public func cornerRadius(for size: CGSize? = nil) -> CGFloat {
        return cornerRadii?.resolved(for: size, mask: mask).uniformCornerRadius ?? 0
    }

    #if canImport(FoundationModels) // Xcode 26
    @available(iOS 26.0, *)
    public func cornerConfiguration(
        size: CGSize? = nil,
        layoutDirectionIsLeftToRight: Bool = true
    ) -> UICornerConfiguration {

        func corner(
            _ cornerRadius: CGFloat?,
            _ isMasked: Bool
        ) -> UICornerRadius? {
            guard isMasked else { return nil }
            if isContainerConcentric {
                return .containerConcentric(minimum: cornerRadius)
            }
            if let cornerRadius {
                return .fixed(cornerRadius)
            }
            return nil
        }

        let cornerRadii = cornerRadii?.resolved(for: size, mask: mask)
        let topLeadingRadius = corner(cornerRadii?.topLeading, mask.contains(.topLeading))
        let topTrailingRadius = corner(cornerRadii?.topTrailing, mask.contains(.topTrailing))
        let bottomLeadingRadius = corner(cornerRadii?.bottomLeading, mask.contains(.bottomLeading))
        let bottomTrailingRadius = corner(cornerRadii?.bottomTrailing, mask.contains(.bottomTrailing))

        let topLeftRadius = layoutDirectionIsLeftToRight
            ? topLeadingRadius
            : topTrailingRadius
        let topRightRadius = layoutDirectionIsLeftToRight
            ? topTrailingRadius
            : topLeadingRadius
        let bottomLeftRadius = layoutDirectionIsLeftToRight
            ? bottomLeadingRadius
            : bottomTrailingRadius
        let bottomRightRadius = layoutDirectionIsLeftToRight
            ? bottomTrailingRadius
            : topLeadingRadius

        return UICornerConfiguration.corners(
            topLeftRadius: topLeftRadius,
            topRightRadius: topRightRadius,
            bottomLeftRadius: bottomLeftRadius,
            bottomRightRadius: bottomRightRadius
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
            view.cornerConfiguration = cornerConfiguration(size: size ?? view.bounds.size)
        }
        #endif
        apply(
            to: view.layer,
            size: size,
            masksToBounds: masksToBounds,
            useCornerRadii: {
                #if canImport(FoundationModels) // Xcode 26
                if #available(iOS 26.0, *) {
                    // `cornerRadii` managed by `cornerConfiguration`
                    return false
                }
                #endif
                return view.layer.hasCornerRadii
            }()
        )
    }

    @MainActor @preconcurrency
    public func apply(
        to layer: CALayer,
        size: CGSize? = nil,
        masksToBounds: Bool = true,
        useCornerRadii: Bool = true
    ) {
        if #available(iOS 16.0, *), useCornerRadii {
            layer.fixCornerRadiiAnimation()
        }
        let cornerRadius = cornerRadius(for: size ?? layer.bounds.size)
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = style.toCoreAnimation()
        layer.masksToBounds = masksToBounds
        layer.maskedCorners = .all
        if #available(iOS 16.0, *), useCornerRadii {
            layer.cornerRadii = CornerRadiusOptions.CornerRadii(cornerRadius: cornerRadius)
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
    public func cornerConfiguration(
        size: CGSize? = nil,
        layoutDirectionIsLeftToRight: Bool = true
    ) -> UICornerConfiguration {
        let maximumRadius = maxCornerRadius.map { Double($0) }
        return UICornerConfiguration.capsule(maximumRadius: maximumRadius)
    }
    #endif
}

extension CornerRadiusOptions.Circle {

    @MainActor @preconcurrency
    public func apply(
        to view: UIView,
        size: CGSize? = nil,
        masksToBounds: Bool = true
    ) {
        #if canImport(FoundationModels) // Xcode 26
        if #available(iOS 26.0, *) {
            view.cornerConfiguration = cornerConfiguration()
        }
        #endif
        apply(
            to: view.layer,
            size: size,
            masksToBounds: masksToBounds,
            useCornerRadii: {
                #if canImport(FoundationModels) // Xcode 26
                if #available(iOS 26.0, *) {
                    // `cornerRadii` managed by `cornerConfiguration`
                    return false
                }
                #endif
                return view.layer.hasCornerRadii
            }()
        )
    }

    @MainActor @preconcurrency
    public func apply(
        to layer: CALayer,
        size: CGSize? = nil,
        masksToBounds: Bool = true,
        useCornerRadii: Bool = true
    ) {
        if #available(iOS 16.0, *), useCornerRadii {
            layer.fixCornerRadiiAnimation()
        }
        let cornerRadius = cornerRadius(for: size ?? layer.bounds.size)
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .circular
        layer.maskedCorners = .all
        layer.masksToBounds = masksToBounds
        if #available(iOS 16.0, *), useCornerRadii {
            layer.cornerRadii = CornerRadiusOptions.CornerRadii(cornerRadius: cornerRadius)
        }
    }

    public func cornerRadius(for size: CGSize? = nil) -> CGFloat {
        guard let size else { return 0 }
        return min(size.width / 2, size.height / 2)
    }

    #if canImport(FoundationModels) // Xcode 26
    @available(iOS 26.0, *)
    public func cornerConfiguration() -> UICornerConfiguration {
        return .capsule()
    }
    #endif
}

extension CornerRadiusOptions.CornerCurve {

    public func toCoreAnimation() -> CALayerCornerCurve {
        switch style {
        case .circular:
            return .circular
        case .continuous:
            return .continuous
        }
    }

    public func toSwiftUI() -> RoundedCornerStyle {
        switch style {
        case .circular:
            return .circular
        case .continuous:
            return .continuous
        }
    }
}

extension CornerRadiusOptions.CornerMask {

    public func toCoreAnimation(
        layoutDirectionIsLeftToRight: Bool = true
    ) -> CACornerMask {
        if self == .all {
            return .all
        } else {
            var mask = CACornerMask()
            if contains(.topLeading) {
                mask.formUnion(layoutDirectionIsLeftToRight ? .topLeft : .topRight)
            }
            if contains(.bottomLeading) {
                mask.formUnion(layoutDirectionIsLeftToRight ? .bottomLeft : .bottomRight)
            }
            if contains(.bottomTrailing) {
                mask.formUnion(layoutDirectionIsLeftToRight ? .bottomRight : .bottomLeft)
            }
            if contains(.topTrailing) {
                mask.formUnion(layoutDirectionIsLeftToRight ? .topRight : .topRight)
            }
            return mask
        }
    }
}

#if canImport(FoundationModels) // Xcode 26
@available(iOS 26.0, *)
extension UICornerConfiguration {

    static var identity: UICornerConfiguration {
        UICornerConfiguration.corners(
            topLeftRadius: .fixed(0),
            topRightRadius: .fixed(0),
            bottomLeftRadius: .fixed(0),
            bottomRightRadius: .fixed(0)
        )
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
        layer.cornerCurve = source.layer.cornerCurve
        layer.maskedCorners = source.layer.maskedCorners
        layer.masksToBounds = source.layer.masksToBounds
        let useCornerRadii = {
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *) {
                // `cornerRadii` managed by `cornerConfiguration`
                return false
            }
            #endif
            return layer.hasCornerRadii
        }()
        if #available(iOS 16.0, *), useCornerRadii {
            layer.cornerRadii = source.layer.cornerRadii
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct CornerRadiusOptions_Previews: PreviewProvider {

    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct CornerRadiusOptionsPreview: View {
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

        struct CornerRadiusViewAdapter: UIViewRepresentable {
            var options: CornerRadiusOptions

            func makeUIView(context: Context) -> CornerRadiusView {
                let uiView = CornerRadiusView()
                uiView.backgroundColor = .red
                return uiView
            }

            func updateUIView(_ uiView: CornerRadiusView, context: Context) {
                UIView.animate(with: context.transaction.animation) {
                    uiView.options = options
                }
            }
        }

        var body: some View {
            CornerRadiusViewAdapter(options: options)

            options
                .fill(Color.blue)

            switch options.storage {
            case .rounded(let options):
                options
                    .fill(Color.yellow)
            case .circle:
                options
                    .fill(Color.yellow)
            case .capsule(let options):
                options
                    .fill(Color.yellow)
            }
        }
    }

    struct Preview: View {

        @State var flag = false

        var body: some View {
            let cornerRadius: CGFloat = flag ? 24 : 12
            VStack {
                VStack {
                    HStack {
                        CornerRadiusOptionsPreview(
                            options: .identity
                        )
                        .frame(width: 50, height: 50)
                    }
                }

                if #available(iOS 15.0, *) {
                    HStack {
                        ContainerRelativeShape()
                            .fill(Color.green)
                            .frame(width: 100, height: 50)
                            .containerShape(RoundedRectangle(cornerRadius: cornerRadius))

                        // Minimum needed for UIKit
                        CornerRadiusOptionsPreview(
                            options: .containerConcentric(
                                minimum: cornerRadius
                            )
                        )
                        .frame(width: 100, height: 50)
                        .containerShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }
                }

                HStack {
                    CornerRadiusOptionsPreview(
                        options: .rounded(
                            cornerRadius: cornerRadius
                        )
                    )
                    .frame(width: 80, height: 50)
                }

                HStack {
                    CornerRadiusOptionsPreview(
                        options: .rounded(
                            cornerRadius: cornerRadius,
                            mask: [.topLeading, .bottomTrailing],
                            style: .circular
                        )
                    )
                    .frame(width: 80, height: 50)
                }

                if #available(iOS 17.0, *) {
                    HStack {
                        CornerRadiusOptionsPreview(
                            options: .rounded(
                                cornerRadius: cornerRadius,
                                mask: [.topLeading, .bottomTrailing],
                                style: .circular
                            )
                        )
                        .frame(width: 80, height: 50)
                        .layoutDirectionBehavior(.mirrors)
                        .environment(\.layoutDirection, .rightToLeft)
                    }
                }

                if #available(iOS 16.0, *) {
                    HStack {
                        CornerRadiusOptionsPreview(
                            options: .unevenRounded(
                                topLeading: cornerRadius,
                                bottomLeading: 4,
                                bottomTrailing: cornerRadius,
                                topTrailing: 4,
                            )
                        )
                        .frame(width: 80, height: 50)
                    }
                }

                HStack {
                    CornerRadiusOptionsPreview(
                        options: .capsule
                    )
                    .frame(width: 100, height: 30)
                }

                HStack {
                    CornerRadiusOptionsPreview(
                        options: .circle
                    )
                    .frame(width: 30, height: 30)
                }

                HStack {
                    CornerRadiusOptionsPreview(
                        options: .rounded(
                            cornerRadius: cornerRadius,
                            style: .continuous
                        )
                    )
                    .frame(width: 100, height: 50)
                }

                HStack {
                    ZStack {
                        CornerRadiusOptions.circle
                            .fill(Color.blue)

                        CornerRadiusOptions.circle
                            .inset(by: 6)
                            .fill(Color.red)

                    }
                    .frame(width: 50, height: 50)

                    ZStack {
                        CornerRadiusOptions.capsule
                            .fill(Color.blue)

                        CornerRadiusOptions.capsule
                            .inset(by: 6)
                            .fill(Color.red)

                    }
                    .frame(width: 100, height: 50)

                    ZStack {
                        CornerRadiusOptions.rounded(
                            cornerRadius: cornerRadius
                        )
                        .fill(Color.blue)

                        CornerRadiusOptions.rounded(
                            cornerRadius: cornerRadius
                        )
                        .inset(by: 6)
                        .fill(Color.red)

                    }
                    .frame(width: 100, height: 50)

                    if #available(iOS 16.0, *) {
                        ZStack {
                            CornerRadiusOptions.unevenRounded(
                                topLeading: cornerRadius,
                                bottomLeading: 4,
                                bottomTrailing: cornerRadius,
                                topTrailing: 4,
                            )
                            .fill(Color.blue)

                            CornerRadiusOptions.unevenRounded(
                                topLeading: cornerRadius,
                                bottomLeading: 4,
                                bottomTrailing: cornerRadius,
                                topTrailing: 4,
                            )
                            .inset(by: 6)
                            .fill(Color.red)

                        }
                        .frame(width: 100, height: 50)
                    }
                }

                Button {
                    withAnimation {
                        flag.toggle()
                    }
                } label: {
                    Text("Toggle")
                }
            }
        }
    }
}

#endif
