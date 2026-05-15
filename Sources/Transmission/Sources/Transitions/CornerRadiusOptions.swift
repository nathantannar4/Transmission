//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@frozen
public enum CornerRadiusOptions: Equatable, Sendable, Shape {

    @frozen
    public struct RoundedRectangle: Equatable, Sendable, Shape {
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

        public nonisolated func path(in rect: CGRect) -> Path {
            if isContainerConcentric, #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                return SwiftUI.ContainerRelativeShape().path(in: rect)
            }
            let cornerRadius = cornerRadius ?? 0
            if mask != .all {
                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                    return UnevenRoundedRectangle(
                        topLeadingRadius: mask.contains(.layerMinXMinYCorner) ? cornerRadius : 0,
                        bottomLeadingRadius: mask.contains(.layerMinXMaxYCorner) ? cornerRadius : 0,
                        bottomTrailingRadius: mask.contains(.layerMaxXMaxYCorner) ? cornerRadius : 0,
                        topTrailingRadius: mask.contains(.layerMaxXMinYCorner) ? cornerRadius : 0,
                        style: style.toSwiftUI()
                    ).path(in: rect)
                }
                return RoundedCornersRectangle(
                    topLeadingRadius: mask.contains(.layerMinXMinYCorner) ? cornerRadius : 0,
                    bottomLeadingRadius: mask.contains(.layerMinXMaxYCorner) ? cornerRadius : 0,
                    bottomTrailingRadius: mask.contains(.layerMaxXMaxYCorner) ? cornerRadius : 0,
                    topTrailingRadius: mask.contains(.layerMaxXMinYCorner) ? cornerRadius : 0,
                    style: style.toSwiftUI()
                ).path(in: rect)
            }
            return SwiftUI.RoundedRectangle(cornerRadius: cornerRadius, style: style.toSwiftUI()).path(in: rect)
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
            let cornerRadius = UIScreen.main.displayCornerRadius
            return RoundedRectangle(
                cornerRadius: max(min, cornerRadius),
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
                cornerRadius: cornerRadius,
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
            layer.cornerRadius = cornerRadius(for: size ?? layer.bounds.size)
            layer.maskedCorners = mask
            layer.cornerCurve = style
            layer.masksToBounds = masksToBounds
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
        if let size {
            let maxCornerRadius = min(size.width / 2, size.height / 2)
            layer.cornerRadius = min(cornerRadius ?? 0, maxCornerRadius)
        } else {
            layer.cornerRadius = cornerRadius ?? 0
        }
        layer.maskedCorners = mask
        layer.cornerCurve = style
        layer.masksToBounds = masksToBounds
    }

    #if canImport(FoundationModels) // Xcode 26
    @available(iOS 26.0, *)
    func makeCornerConfiguration() -> UICornerConfiguration {
        let corner = isContainerConcentric
            ? UICornerRadius.containerConcentric(minimum: cornerRadius)
            : cornerRadius.map { .fixed($0) }
        return UICornerConfiguration.corners(
            topLeftRadius: mask.contains(.layerMinXMinYCorner) ? corner : nil,
            topRightRadius: mask.contains(.layerMaxXMinYCorner) ? corner : nil,
            bottomLeftRadius: mask.contains(.layerMinXMaxYCorner) ? corner : nil,
            bottomRightRadius: mask.contains(.layerMaxXMaxYCorner) ? corner : nil
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
        layer.cornerRadius = cornerRadius(for: size ?? layer.bounds.size)
        layer.cornerCurve = style
        layer.masksToBounds = masksToBounds
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
    static let all: CACornerMask = [
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
