//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

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
        size: CGSize? = nil,
        masksToBounds: Bool = true
    ) {
        let size = size ?? view.bounds.size
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
        apply(to: view.layer, size: size ?? view.bounds.size, masksToBounds: masksToBounds)
    }

    @MainActor @preconcurrency
    public func apply(
        to layer: CALayer,
        size: CGSize? = nil,
        masksToBounds: Bool = true
    ) {
        let size = size ?? layer.bounds.size
        let maxCornerRadius = min(size.width / 2, size.height / 2)
        layer.cornerRadius = min(cornerRadius ?? 0, maxCornerRadius)
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
        apply(to: view.layer, size: size ?? view.bounds.size, masksToBounds: masksToBounds)
    }

    @MainActor @preconcurrency
    public func apply(
        to layer: CALayer,
        size: CGSize? = nil,
        masksToBounds: Bool = true
    ) {
        layer.cornerRadius = cornerRadius(for: size ?? layer.bounds.size)
        layer.cornerCurve = style
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
}

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
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct CornerRadiusOptions_Previews: PreviewProvider {

    struct Preview: View {
        var color: Color = .blue
        var options: CornerRadiusOptions

        class UIViewType: UIView {
            var options: CornerRadiusOptions = .identity

            override func layoutSubviews() {
                super.layoutSubviews()
                options.apply(to: self)
                print(layer.cornerRadius)
            }
        }

        var body: some View {
            ViewRepresentableAdapter {
                let uiView = UIViewType()
                uiView.options = options
                uiView.backgroundColor = color.toUIColor()
                return uiView
            }
        }
    }

    static var previews: some View {
        VStack {
            Preview(options: .identity)
                .frame(width: 50, height: 50)

            HStack {
                Preview(options: .rounded(cornerRadius: 12))
                    .frame(width: 100, height: 50)

                Preview(options: .containerConcentric(minimum: 12))
                    .frame(width: 100, height: 50)

                Preview(
                    options: .rounded(
                        cornerRadius: 12,
                        mask: [.layerMaxXMaxYCorner, .layerMinXMinYCorner],
                        style: .circular
                    )
                )
                .frame(width: 100, height: 50)
            }

            HStack {
                Preview(options: .capsule)
                    .frame(width: 100, height: 30)

                Preview(options: .circle)
                    .frame(width: 30, height: 30)
            }

            ZStack {
                Preview(
                    color: .red,
                    options: .rounded(cornerRadius: 16)
                )
                .frame(width: 100, height: 50)

                Preview(
                    options: .rounded(cornerRadius: 16, style: .continuous)
                )
                .frame(width: 100, height: 50)
            }
        }
    }
}

#endif
