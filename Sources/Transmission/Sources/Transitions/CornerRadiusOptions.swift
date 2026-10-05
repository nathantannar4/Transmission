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
    public struct CornerStyle: Equatable, Sendable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
        @usableFromInline
        enum Storage: Equatable, Sendable {
            case fixed(CGFloat)
            case screen(minimum: CGFloat?, prefersContainerConcentric: Bool)
            case containerConcentric(minimum: CGFloat?)
        }
        @usableFromInline
        var storage: Storage

        private init(storage: Storage) {
            self.storage = storage
        }

        public init(floatLiteral value: Double) {
            self.storage = .fixed(CGFloat(value))
        }

        public init(integerLiteral value: Int) {
            self.storage = .fixed(CGFloat(value))
        }

        public static func fixed(_ fixed: CGFloat) -> CornerStyle {
            CornerStyle(storage: .fixed(fixed))
        }

        public static func screen(minimum: CGFloat? = 8, prefersContainerConcentric: Bool = true) -> CornerStyle {
            CornerStyle(storage: .screen(minimum: minimum, prefersContainerConcentric: prefersContainerConcentric))
        }

        @available(iOS 26.0, *)
        public static var containerConcentric: CornerStyle {
            CornerStyle(storage: .containerConcentric(minimum: nil))
        }

        @available(iOS 26.0, *)
        public static func containerConcentric(minimum: CGFloat?) -> CornerStyle {
            CornerStyle(storage: .containerConcentric(minimum: minimum))
        }

        public var isContainerConcentric: Bool {
            switch storage {
            case .fixed:
                return false
            case .screen(_, let prefersContainerConcentric):
                if #available(iOS 26.0, *) {
                    return prefersContainerConcentric
                }
                return false
            case .containerConcentric:
                return true
            }
        }

        public var fixed: CGFloat? {
            switch storage {
            case .fixed(let fixed):
                return fixed
            case .screen, .containerConcentric:
                return nil
            }
        }

        public func min(_ upperLimit: CGFloat) -> CornerStyle {
            switch storage {
            case .fixed(let fixed):
                return .fixed(Swift.min(fixed, upperLimit))
            case .screen, .containerConcentric:
                return self
            }
        }

        public func max(_ lowerLimit: CGFloat) -> CornerStyle {
            switch storage {
            case .fixed(let fixed):
                return .fixed(Swift.max(fixed, lowerLimit))
            case .screen(let minimum, let prefersContainerConcentric):
                return .screen(minimum: Swift.max(minimum ?? 0, lowerLimit), prefersContainerConcentric: prefersContainerConcentric)
            case .containerConcentric(let minimum):
                return CornerStyle(storage: .containerConcentric(minimum: Swift.max(minimum ?? 0, lowerLimit)))
            }
        }

        public func scaled(by scale: CGFloat) -> CornerStyle {
            switch storage {
            case .fixed(let fixed):
                return .fixed(fixed * scale)
            case .screen, .containerConcentric:
                return self
            }
        }

        @available(iOS 26.0, *)
        public func toSwiftUI() -> Edge.Corner.Style {
            switch storage {
            case .fixed(let fixed):
                return .fixed(fixed)
            case .screen(let minimum, _), .containerConcentric(let minimum):
                return .concentric(minimum: minimum.map({ .fixed($0) }))
            }
        }

        @available(iOS 26.0, *)
        public func toUIKit() -> UICornerRadius {
            switch storage {
            case .fixed(let fixed):
                return .fixed(fixed)
            case .screen(let minimum, _), .containerConcentric(let minimum):
                return .containerConcentric(minimum: minimum)
            }
        }

        public func resolved(displayCornerRadius: CGFloat?) -> CornerStyle {
            switch storage {
            case .fixed, .containerConcentric:
                return self
            case .screen(let minimum, let prefersContainerConcentric):
                if #available(iOS 26.0, *), prefersContainerConcentric {
                    return self
                }
                return .fixed(Swift.max(minimum ?? 0, displayCornerRadius ?? 0))
            }
        }
    }

    @frozen
    public struct CornerRadii: Equatable, Sendable {

        public var topLeading: CornerStyle
        public var bottomLeading: CornerStyle
        public var bottomTrailing: CornerStyle
        public var topTrailing: CornerStyle

        public var uniformCornerRadius: CGFloat? {
            switch (topLeading.storage, bottomLeading.storage, bottomTrailing.storage, topTrailing.storage) {
            case (.fixed(let topLeading), .fixed(let bottomLeading), .fixed(let bottomTrailing), .fixed(let topTrailing)):
                if topLeading == bottomLeading, bottomLeading == bottomTrailing, bottomTrailing == topTrailing {
                    return topTrailing
                }
            default:
                break
            }
            return nil
        }

        public var isContainerConcentric: Bool {
            topLeading.isContainerConcentric || bottomLeading.isContainerConcentric || bottomTrailing.isContainerConcentric || topTrailing.isContainerConcentric
        }

        public var mask: CornerMask {
            var mask = CornerMask.all
            if topLeading.fixed == 0 {
                mask.remove(.topLeading)
            }
            if bottomLeading.fixed == 0 {
                mask.remove(.bottomLeading)
            }
            if bottomTrailing.fixed == 0 {
                mask.remove(.bottomTrailing)
            }
            if topTrailing.fixed == 0 {
                mask.remove(.topTrailing)
            }
            return mask
        }

        public init(
            topLeading: CornerStyle,
            bottomLeading: CornerStyle,
            bottomTrailing: CornerStyle,
            topTrailing: CornerStyle
        ) {
            self.topLeading = topLeading
            self.topTrailing = topTrailing
            self.bottomLeading = bottomLeading
            self.bottomTrailing = bottomTrailing
        }

        public init(
            cornerRadius: CornerStyle
        ) {
            self.init(
                topLeading: cornerRadius,
                bottomLeading: cornerRadius,
                bottomTrailing: cornerRadius,
                topTrailing: cornerRadius,
            )
        }

        public init(
            topLeading: CGFloat,
            bottomLeading: CGFloat,
            bottomTrailing: CGFloat,
            topTrailing: CGFloat
        ) {
            self.init(
                topLeading: .fixed(topLeading),
                bottomLeading: .fixed(bottomLeading),
                bottomTrailing: .fixed(bottomTrailing),
                topTrailing: .fixed(topTrailing)
            )
        }

        public init(
            cornerRadius: CGFloat
        ) {
            self.init(cornerRadius: .fixed(cornerRadius))
        }

        public func scaled(by scale: CGFloat) -> CornerRadii {
            var scaled = self
            scaled.topLeading = topLeading.scaled(by: scale)
            scaled.bottomLeading = bottomLeading.scaled(by: scale)
            scaled.bottomTrailing = bottomTrailing.scaled(by: scale)
            scaled.topTrailing = topTrailing.scaled(by: scale)
            return scaled
        }

        public func min(_ upperLimit: CGFloat) -> CornerRadii {
            var limited = self
            limited.topLeading = topLeading.min(upperLimit)
            limited.bottomLeading = bottomLeading.min(upperLimit)
            limited.bottomTrailing = bottomTrailing.min(upperLimit)
            limited.topTrailing = topTrailing.min(upperLimit)
            return limited
        }

        public func max(_ upperLimit: CGFloat) -> CornerRadii {
            var limited = self
            limited.topLeading = topLeading.max(upperLimit)
            limited.bottomLeading = bottomLeading.max(upperLimit)
            limited.bottomTrailing = bottomTrailing.max(upperLimit)
            limited.topTrailing = topTrailing.max(upperLimit)
            return limited
        }

        public func masked(_ mask: CornerMask) -> CornerRadii {
            guard mask != .all else { return self }
            let masked = CornerRadii(
                topLeading: mask.contains(.topLeading) ? topLeading : .fixed(0),
                bottomLeading: mask.contains(.bottomLeading) ? bottomLeading : .fixed(0),
                bottomTrailing: mask.contains(.bottomTrailing) ? bottomTrailing : .fixed(0),
                topTrailing: mask.contains(.topTrailing) ? topTrailing : .fixed(0),
            )
            return masked
        }

        public func resolved(for size: CGSize? = nil) -> CornerRadii {
            guard let size, size.width > 0, size.height > 0 else { return self }
            let limit = Swift.min(size.width / 2, size.height / 2)
            let bounded = min(limit)
            return bounded
        }

        @MainActor @preconcurrency
        public func resolved(for size: CGSize? = nil, in window: UIWindow? = nil) -> CornerRadii {
            let displayCornerRadius = (window?.screen ?? UIScreen.main).displayCornerRadius
            let resolved = resolved(for: size)
            return CornerRadii(
                topLeading: resolved.topLeading.resolved(displayCornerRadius: displayCornerRadius),
                bottomLeading: resolved.bottomLeading.resolved(displayCornerRadius: displayCornerRadius),
                bottomTrailing: resolved.bottomTrailing.resolved(displayCornerRadius: displayCornerRadius),
                topTrailing: resolved.topTrailing.resolved(displayCornerRadius: displayCornerRadius),
            )
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

        public var cornerRadii: CornerRadii
        public var mask: CornerMask
        public var style: CornerCurve

        public static let identity: RoundedRectangle = .rounded(cornerRadius: 0)

        public static func rounded(
            cornerRadius: CGFloat,
            mask: CornerMask = .all,
            style: CornerCurve = .continuous
        ) -> RoundedRectangle {
            RoundedRectangle(
                cornerRadii: CornerRadii(
                    cornerRadius: .fixed(cornerRadius)
                ),
                mask: mask,
                style: style
            )
        }

        @available(iOS 16.0, *)
        public static func unevenRounded(
            cornerRadii: CornerRadii,
            mask: CornerMask = .all,
            style: CornerCurve = .continuous
        ) -> RoundedRectangle {
            RoundedRectangle(
                cornerRadii: cornerRadii,
                mask: mask,
                style: style
            )
        }

        @available(iOS 16.0, *)
        public static func unevenRounded(
            topLeading: CornerStyle,
            bottomLeading: CornerStyle,
            bottomTrailing: CornerStyle,
            topTrailing: CornerStyle,
            mask: CornerMask = .all,
            style: CornerCurve = .continuous
        ) -> RoundedRectangle {
            .unevenRounded(
                cornerRadii: CornerRadii(
                    topLeading: topLeading,
                    bottomLeading: bottomLeading,
                    bottomTrailing: bottomTrailing,
                    topTrailing: topTrailing,
                ),
                mask: mask,
                style: style
            )
        }

        @available(iOS 16.0, *)
        public static func unevenRounded(
            topLeading: CGFloat,
            bottomLeading: CGFloat,
            bottomTrailing: CGFloat,
            topTrailing: CGFloat,
            mask: CornerMask = .all,
            style: CornerCurve = .continuous
        ) -> RoundedRectangle {
            .unevenRounded(
                cornerRadii: CornerRadii(
                    topLeading: .fixed(topLeading),
                    bottomLeading: .fixed(bottomLeading),
                    bottomTrailing: .fixed(bottomTrailing),
                    topTrailing: .fixed(topTrailing),
                ),
                mask: mask,
                style: style
            )
        }

        public static func screen(
            minimum: CGFloat? = 8,
            mask: CornerMask = .all,
            prefersContainerConcentric: Bool = true
        ) -> RoundedRectangle {
            RoundedRectangle(
                cornerRadii: CornerRadii(
                    cornerRadius: .screen(
                        minimum: minimum,
                        prefersContainerConcentric: prefersContainerConcentric
                    )
                ),
                mask: mask,
                style: .circular
            )
        }

        @available(iOS 26.0, *)
        public static func containerConcentric(
            minimum: CGFloat?,
            mask: CornerMask = .all,
            style: CornerCurve = .continuous
        ) -> RoundedRectangle {
            RoundedRectangle(
                cornerRadii: CornerRadii(
                    cornerRadius: .containerConcentric(minimum: minimum)
                ),
                mask: mask,
                style: style
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

    @MainActor @preconcurrency
    public func cornerRadius(for size: CGSize? = nil, in window: UIWindow? = nil) -> CGFloat? {
        switch storage {
        case .rounded(let options):
            return options.cornerRadius(for: size, in: window)
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
        mask: CornerMask = .all,
        style: CornerCurve = .continuous
    ) -> CornerRadiusOptions {
        CornerRadiusOptions(
            storage: .rounded(
                .unevenRounded(
                    cornerRadii: cornerRadii,
                    mask: mask,
                    style: style
                )
            )
        )
    }

    @available(iOS 16.0, *)
    public static func unevenRounded(
        topLeading: CornerStyle,
        bottomLeading: CornerStyle,
        bottomTrailing: CornerStyle,
        topTrailing: CornerStyle,
        mask: CornerMask = .all,
        style: CornerCurve = .continuous
    ) -> CornerRadiusOptions {
        .unevenRounded(
            cornerRadii: CornerRadii(
                topLeading: topLeading,
                bottomLeading: bottomLeading,
                bottomTrailing: bottomTrailing,
                topTrailing: topTrailing
            ),
            mask: mask,
            style: style
        )
    }

    @available(iOS 16.0, *)
    public static func unevenRounded(
        topLeading: CGFloat,
        bottomLeading: CGFloat,
        bottomTrailing: CGFloat,
        topTrailing: CGFloat,
        mask: CornerMask = .all,
        style: CornerCurve = .continuous
    ) -> CornerRadiusOptions {
        .unevenRounded(
            topLeading: .fixed(topLeading),
            bottomLeading: .fixed(bottomLeading),
            bottomTrailing: .fixed(bottomTrailing),
            topTrailing: .fixed(topTrailing),
            mask: mask,
            style: style
        )
    }

    public static func screen(
        minimum: CGFloat? = 8,
        mask: CornerMask = .all,
        prefersContainerConcentric: Bool = true
    ) -> CornerRadiusOptions {
        CornerRadiusOptions(
            storage: .rounded(
                .screen(
                    minimum: minimum,
                    mask: mask,
                    prefersContainerConcentric: prefersContainerConcentric
                )
            )
        )
    }

    @available(iOS 26.0, *)
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

    public func scaled(by scale: CGFloat) -> CornerRadiusOptions {
        switch storage {
        case .rounded(let options):
            return CornerRadiusOptions(
                storage: .rounded(
                    options.scaled(by: scale)
                )
            )
        case .circle, .capsule:
            return self
        }
    }

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

extension CornerRadiusOptions.CornerStyle: Animatable {

    public var animatableData: CGFloat {
        get {
            switch storage {
            case .fixed(let fixed):
                return fixed
            case .screen(let minimum, _), .containerConcentric(let minimum):
                return minimum ?? 0
            }
        }
        set {
            switch storage {
            case .fixed:
                storage = .fixed(newValue)
            case .screen(_, let prefersContainerConcentric):
                storage = .screen(minimum: newValue, prefersContainerConcentric: prefersContainerConcentric)
            case .containerConcentric:
                storage = .containerConcentric(minimum: newValue)
            }
        }
    }
}

extension CornerRadiusOptions.CornerRadii: Animatable {

    public typealias AnimatableData = AnimatablePair<AnimatablePair<CornerRadiusOptions.CornerStyle.AnimatableData, CornerRadiusOptions.CornerStyle.AnimatableData>, AnimatablePair<CornerRadiusOptions.CornerStyle.AnimatableData, CornerRadiusOptions.CornerStyle.AnimatableData>>
    public var animatableData: AnimatableData {
        get {
            AnimatablePair(
                AnimatablePair(
                    topLeading.animatableData,
                    bottomLeading.animatableData
                ),
                AnimatablePair(
                    bottomTrailing.animatableData,
                    topTrailing.animatableData
                )
            )
        }
        set {
            topLeading.animatableData = newValue.first.first
            bottomLeading.animatableData = newValue.first.second
            bottomTrailing.animatableData = newValue.second.first
            topTrailing.animatableData = newValue.second.second
        }
    }
}

extension CornerRadiusOptions.RoundedRectangle: Shape, InsettableShape {

    public typealias AnimatableData = CornerRadiusOptions.CornerRadii.AnimatableData
    public var animatableData: AnimatableData {
        get { cornerRadii.animatableData }
        set { cornerRadii.animatableData = newValue }
    }

    public nonisolated func path(in rect: CGRect) -> Path {
        let cornerRadii = cornerRadii.resolved(for: rect.size)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *), cornerRadii.isContainerConcentric {
            return ConcentricRectangle(
                topLeadingCorner: cornerRadii.topLeading.toSwiftUI(),
                topTrailingCorner: cornerRadii.topTrailing.toSwiftUI(),
                bottomLeadingCorner: cornerRadii.bottomLeading.toSwiftUI(),
                bottomTrailingCorner: cornerRadii.bottomTrailing.toSwiftUI()
            ).path(in: rect)
        }
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return SwiftUI.UnevenRoundedRectangle(
                topLeadingRadius: cornerRadii.topLeading.fixed ?? 0,
                bottomLeadingRadius: cornerRadii.bottomLeading.fixed ?? 0,
                bottomTrailingRadius: cornerRadii.bottomTrailing.fixed ?? 0,
                topTrailingRadius: cornerRadii.topTrailing.fixed ?? 0,
                style: style.toSwiftUI()
            ).path(in: rect)
        }
        return Engine.RoundedCornersRectangle(
            topLeadingRadius: cornerRadii.topLeading.fixed ?? 0,
            bottomLeadingRadius: cornerRadii.bottomLeading.fixed ?? 0,
            bottomTrailingRadius: cornerRadii.bottomTrailing.fixed ?? 0,
            topTrailingRadius: cornerRadii.topTrailing.fixed ?? 0,
            style: style.toSwiftUI()
        ).path(in: rect)
    }

    public nonisolated func inset(by amount: CGFloat) -> Engine.AnyShape {
        let cornerRadii = cornerRadii.resolved()
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *), cornerRadii.isContainerConcentric {
            return AnyShape(
                shape: ConcentricRectangle(
                    topLeadingCorner: cornerRadii.topLeading.toSwiftUI(),
                    topTrailingCorner: cornerRadii.topTrailing.toSwiftUI(),
                    bottomLeadingCorner: cornerRadii.bottomLeading.toSwiftUI(),
                    bottomTrailingCorner: cornerRadii.bottomTrailing.toSwiftUI()
                ).inset(dx: amount, dy: amount)
            )
        }
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return AnyShape(
                shape: SwiftUI.UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadii.topLeading.fixed ?? 0,
                    bottomLeadingRadius: cornerRadii.bottomLeading.fixed ?? 0,
                    bottomTrailingRadius: cornerRadii.bottomTrailing.fixed ?? 0,
                    topTrailingRadius: cornerRadii.topTrailing.fixed ?? 0,
                    style: style.toSwiftUI()
                ).inset(by: amount)
            )
        }
        return AnyShape(
            shape: Engine.RoundedCornersRectangle(
                topLeadingRadius: cornerRadii.topLeading.fixed ?? 0,
                bottomLeadingRadius: cornerRadii.bottomLeading.fixed ?? 0,
                bottomTrailingRadius: cornerRadii.bottomTrailing.fixed ?? 0,
                topTrailingRadius: cornerRadii.topTrailing.fixed ?? 0,
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

#if XCODE_26
extension CornerRadiusOptions: RoundedRectangularShape {

    @available(iOS 26.0, *)
    public func corners(in size: CGSize?) -> Corners? {
        switch storage {
        case .rounded(let options):
            return options.corners(in: size)
        case .circle(let options):
            let radius = options.cornerRadius(for: size)
            return RoundedRectangularShapeCorners(all: .fixed(radius))
        case .capsule(let options):
            return options.corners(in: size)
        }
    }
}

extension CornerRadiusOptions.RoundedRectangle: RoundedRectangularShape {

    @available(iOS 26.0, *)
    public func corners(in size: CGSize?) -> Corners? {
        let cornerRadii = cornerRadii.resolved(for: size)
        return Corners(
            topLeading: cornerRadii.topLeading.toSwiftUI(),
            topTrailing: cornerRadii.topTrailing.toSwiftUI(),
            bottomLeading: cornerRadii.bottomLeading.toSwiftUI(),
            bottomTrailing: cornerRadii.bottomTrailing.toSwiftUI()
        )
    }
}

extension CornerRadiusOptions.Capsule: RoundedRectangularShape {

    @available(iOS 26.0, *)
    public func corners(in size: CGSize?) -> Corners? {
        let cornerRadius = cornerRadius(for: size)
        return Corners(all: .fixed(cornerRadius ?? 0))
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
    public func setCornerRadius(
        to view: UIView,
        size: CGSize? = nil,
        prefersMasksToBounds: Bool = true,
        prefersEffectiveMinimium: Bool = false
    ) {
        switch storage {
        case .rounded(let options):
            options.setCornerRadius(
                to: view,
                size: size,
                prefersMasksToBounds: prefersMasksToBounds,
                prefersEffectiveMinimium: prefersEffectiveMinimium
            )

        case .circle(let options):
            options.setCornerRadius(
                to: view,
                size: size,
                prefersMasksToBounds: prefersMasksToBounds
            )

        case .capsule(let options):
            options.setCornerRadius(
                to: view,
                size: size,
                prefersMasksToBounds: prefersMasksToBounds
            )
        }
    }

    @MainActor @preconcurrency
    public func setCornerRadius(
        to layer: CALayer,
        size: CGSize? = nil,
        in window: UIWindow? = nil,
        prefersMasksToBounds: Bool = true,
        useCornerRadii: Bool = true,
        layoutDirectionIsLeftToRight: Bool = true
    ) {
        switch storage {
        case .rounded(let options):
            options.setCornerRadius(
                to: layer,
                size: size,
                in: window,
                prefersMasksToBounds: prefersMasksToBounds,
                useCornerRadii: useCornerRadii,
                layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight
            )
        case .capsule(let options):
            options.setCornerRadius(
                to: layer,
                size: size,
                prefersMasksToBounds: prefersMasksToBounds,
                useCornerRadii: useCornerRadii
            )
        case .circle(let options):
            options.setCornerRadius(
                to: layer,
                size: size,
                prefersMasksToBounds: prefersMasksToBounds,
                useCornerRadii: useCornerRadii
            )
        }
    }

    #if XCODE_26
    @MainActor @preconcurrency
    @available(iOS 26.0, *)
    public func cornerConfiguration(
        size: CGSize? = nil,
        in window: UIWindow? = nil,
        layoutDirectionIsLeftToRight: Bool = true
    ) -> UICornerConfiguration {
        switch storage {
        case .rounded(let options):
            return options.cornerConfiguration(
                size: size,
                in: window,
                layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight
            )
        case .circle(let options):
            return options.cornerConfiguration()
        case .capsule(let options):
            return options.cornerConfiguration(
                layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight
            )
        }
    }
    #endif
}

extension CornerRadiusOptions.RoundedRectangle {

    public func scaled(by scale: CGFloat) -> CornerRadiusOptions.RoundedRectangle {
        var scaled = self
        scaled.cornerRadii = cornerRadii.scaled(by: scale)
        return scaled
    }

    @MainActor @preconcurrency
    public func setCornerRadius(
        to view: UIView,
        size: CGSize? = nil,
        prefersMasksToBounds: Bool = true,
        prefersEffectiveMinimium: Bool = false
    ) {
        let layoutDirectionIsLeftToRight = view.effectiveUserInterfaceLayoutDirection == .leftToRight
        #if XCODE_26
        if #available(iOS 26.0, *) {
            let cornerConfiguration = cornerConfiguration(
                size: size ?? view.bounds.size,
                in: view.window,
                layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight
            )
            view.cornerConfiguration = cornerConfiguration
            if prefersEffectiveMinimium {
                // When a view is transformed outside the containing view bounds, the concentric corner resolution will resolve to 0
                var cornerRadii = cornerRadii
                cornerRadii.topLeading = cornerRadii.topLeading.max(
                    view.effectiveRadius(corner: layoutDirectionIsLeftToRight ? .topLeft : .topRight)
                )
                cornerRadii.bottomLeading = cornerRadii.bottomLeading.max(
                    view.effectiveRadius(corner: layoutDirectionIsLeftToRight ? .bottomLeft : .bottomRight)
                )
                cornerRadii.bottomTrailing = cornerRadii.bottomTrailing.max(
                    view.effectiveRadius(corner: layoutDirectionIsLeftToRight ? .bottomRight : .bottomLeft)
                )
                cornerRadii.topTrailing = cornerRadii.topTrailing.max(
                    view.effectiveRadius(corner: layoutDirectionIsLeftToRight ? .topRight : .topLeft)
                )
                let options = CornerRadiusOptions.RoundedRectangle(cornerRadii: cornerRadii, mask: mask, style: style)
                view.cornerConfiguration = options.cornerConfiguration(
                    size: size ?? view.bounds.size,
                    in: view.window,
                    layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight
                )
            }
        }
        #endif
        setCornerRadius(
            to: view.layer,
            size: size,
            in: view.window,
            prefersMasksToBounds: prefersMasksToBounds && view.clipsToBounds,
            useCornerRadii: {
                #if XCODE_26
                if #available(iOS 26.0, *) {
                    // `cornerRadii` managed by `cornerConfiguration`
                    return false
                }
                #endif
                return view.layer.hasCornerRadii || cornerRadii.uniformCornerRadius == nil
            }(),
            layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight
        )
    }

    @MainActor @preconcurrency
    public func setCornerRadius(
        to layer: CALayer,
        size: CGSize? = nil,
        in window: UIWindow? = nil,
        prefersMasksToBounds: Bool = true,
        useCornerRadii: Bool = true,
        layoutDirectionIsLeftToRight: Bool = true
    ) {
        if #available(iOS 16.0, *), useCornerRadii {
            layer.fixCornerRadiiAnimation()
        }
        let cornerRadii = cornerRadii.resolved(for: size, in: window)
        let uniformCornerRadius = cornerRadii.uniformCornerRadius
        if uniformCornerRadius != nil || !cornerRadii.isContainerConcentric {
            layer.cornerRadius = uniformCornerRadius ?? 0
        }
        layer.cornerCurve = style.toCoreAnimation()
        layer.maskedCorners = cornerRadii.mask.toCoreAnimation(layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight)
        layer.masksToBounds = prefersMasksToBounds
        if #available(iOS 16.0, *), useCornerRadii {
            layer.cornerRadii = cornerRadii
        }
    }

    @MainActor @preconcurrency
    public func cornerRadius(for size: CGSize? = nil, in window: UIWindow? = nil) -> CGFloat? {
        let cornerRadii = cornerRadii.resolved(for: size, in: window)
        if let uniformCornerRadius = cornerRadii.uniformCornerRadius {
            return uniformCornerRadius
        }
        return nil
    }

    #if XCODE_26
    @MainActor @preconcurrency
    @available(iOS 26.0, *)
    public func cornerConfiguration(
        size: CGSize? = nil,
        in window: UIWindow? = nil,
        layoutDirectionIsLeftToRight: Bool = true
    ) -> UICornerConfiguration {

        let cornerRadii = cornerRadii.resolved(for: size, in: window)
        let topLeadingRadius = cornerRadii.topLeading.toUIKit()
        let topTrailingRadius = cornerRadii.topTrailing.toUIKit()
        let bottomLeadingRadius = cornerRadii.bottomLeading.toUIKit()
        let bottomTrailingRadius = cornerRadii.bottomTrailing.toUIKit()

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
            : bottomLeadingRadius

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
    public func setCornerRadius(
        to view: UIView,
        size: CGSize? = nil,
        prefersMasksToBounds: Bool = true
    ) {
        #if XCODE_26
        if #available(iOS 26.0, *) {
            let cornerConfiguration = cornerConfiguration()
            view.cornerConfiguration = cornerConfiguration
        }
        #endif
        setCornerRadius(
            to: view.layer,
            size: size,
            prefersMasksToBounds: prefersMasksToBounds,
            useCornerRadii: {
                #if XCODE_26
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
    public func setCornerRadius(
        to layer: CALayer,
        size: CGSize? = nil,
        prefersMasksToBounds: Bool = true,
        useCornerRadii: Bool = true
    ) {
        if #available(iOS 16.0, *), useCornerRadii {
            layer.fixCornerRadiiAnimation()
        }
        let cornerRadius = cornerRadius(for: size ?? layer.bounds.size) ?? 0
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = style.toCoreAnimation()
        layer.maskedCorners = .all
        layer.masksToBounds = prefersMasksToBounds && cornerRadius != 0
        if #available(iOS 16.0, *), useCornerRadii {
            layer.cornerRadii = CornerRadiusOptions.CornerRadii(cornerRadius: .fixed(cornerRadius))
        }
    }

    public func cornerRadius(
        for size: CGSize? = nil
    ) -> CGFloat? {
        if let size {
            let idealCornerRadius = min(size.width / 2, size.height / 2)
            return max(min(minCornerRadius ?? 0, idealCornerRadius), min(maxCornerRadius ?? .infinity, idealCornerRadius))
        }
        return minCornerRadius
    }

    #if XCODE_26
    @available(iOS 26.0, *)
    public func cornerConfiguration(
        layoutDirectionIsLeftToRight: Bool = true
    ) -> UICornerConfiguration {
        let maximumRadius = maxCornerRadius.map { Double($0) }
        return UICornerConfiguration.capsule(maximumRadius: maximumRadius)
    }
    #endif
}

extension CornerRadiusOptions.Circle {

    @MainActor @preconcurrency
    public func setCornerRadius(
        to view: UIView,
        size: CGSize? = nil,
        prefersMasksToBounds: Bool = true
    ) {
        #if XCODE_26
        if #available(iOS 26.0, *) {
            view.cornerConfiguration = cornerConfiguration()
        }
        #endif
        setCornerRadius(
            to: view.layer,
            size: size,
            prefersMasksToBounds: prefersMasksToBounds,
            useCornerRadii: {
                #if XCODE_26
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
    public func setCornerRadius(
        to layer: CALayer,
        size: CGSize? = nil,
        prefersMasksToBounds: Bool = true,
        useCornerRadii: Bool = true
    ) {
        if #available(iOS 16.0, *), useCornerRadii {
            layer.fixCornerRadiiAnimation()
        }
        let cornerRadius = cornerRadius(for: size ?? layer.bounds.size)
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .circular
        layer.maskedCorners = .all
        layer.masksToBounds = prefersMasksToBounds && cornerRadius != 0
        if #available(iOS 16.0, *), useCornerRadii {
            layer.cornerRadii = CornerRadiusOptions.CornerRadii(cornerRadius: .fixed(cornerRadius))
        }
    }

    public func cornerRadius(for size: CGSize? = nil) -> CGFloat {
        guard let size else { return 0 }
        return min(size.width / 2, size.height / 2)
    }

    #if XCODE_26
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
                mask.formUnion(layoutDirectionIsLeftToRight ? .topRight : .topLeft)
            }
            return mask
        }
    }
}

#if XCODE_26
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

    public func setCornerRadius(
        _ cornerRadius: CornerRadiusOptions,
        prefersMasksToBounds: Bool = true,
        prefersEffectiveMinimium: Bool = false
    ) {
        cornerRadius.setCornerRadius(
            to: self,
            prefersMasksToBounds: prefersMasksToBounds,
            prefersEffectiveMinimium: prefersEffectiveMinimium
        )
    }

    public func setCornerRadius(from source: UIView) {
        #if XCODE_26
        if #available(iOS 26.0, *) {
            cornerConfiguration = source.cornerConfiguration
        }
        #endif
        layer.cornerRadius = source.layer.cornerRadius
        layer.cornerCurve = source.layer.cornerCurve
        layer.maskedCorners = source.layer.maskedCorners
        layer.masksToBounds = source.layer.masksToBounds
        let useCornerRadii = {
            #if XCODE_26
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
                    options.setCornerRadius(to: self)
                }
            }

            override func layoutSubviews() {
                super.layoutSubviews()
                if #unavailable(iOS 26.0) {
                    options.setCornerRadius(to: self)
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

                if #available(iOS 26.0, *) {
                    HStack {
                        ConcentricRectangle(corners: .concentric(minimum: .fixed(cornerRadius)))
                            .fill(Color.green)
                            .frame(width: 100, height: 50)

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
