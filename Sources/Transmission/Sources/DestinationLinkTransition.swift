//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// The transition and presentation style for a ``DestinationLink`` or ``DestinationLinkModifier``.
@available(iOS 14.0, *)
public struct DestinationLinkTransition: Sendable {
    enum Value: @unchecked Sendable {
        case `default`(Options)
        case zoom(Options)
        case representable(Options, any DestinationLinkTransitionRepresentable)

        var options: Options {
            switch self {
            case .default(let options), .zoom(let options), .representable(let options, _):
                return options
            }
        }
    }
    var value: Value

    /// The default presentation style of the `UINavigationController`.
    public static let `default`: DestinationLinkTransition = DestinationLinkTransition(value: .default(.init()))

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static let zoom = DestinationLinkTransition(value: .zoom(.init()))

    /// The zoom presentation style if available, otherwise the default transition style.
    public static var zoomIfAvailable: DestinationLinkTransition {
        if #available(iOS 18.0, *) {
            return .zoom
        }
        return .default
    }

    /// A custom presentation style.
    public static func custom<T: DestinationLinkTransitionRepresentable>(_ transition: T) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .representable(.init(), transition))
    }
}

@available(iOS 14.0, *)
extension DestinationLinkTransition {
    /// The transition options.
    @frozen
    public struct Options {
        /// Used when the presentation delegate asks if it should dismiss
        public var isInteractive: Bool
        /// When `true`, the destination will be dismissed when the presentation source is dismantled
        public var shouldAutomaticallyDismissDestination: Bool
        public var preferredPresentationBackgroundColor: Color?
        public var hidesBottomBarWhenPushed: Bool

        public init(
            isInteractive: Bool = true,
            shouldAutomaticallyDismissDestination: Bool = true,
            preferredPresentationBackgroundColor: Color? = nil,
            hidesBottomBarWhenPushed: Bool = false
        ) {
            self.isInteractive = isInteractive
            self.shouldAutomaticallyDismissDestination = shouldAutomaticallyDismissDestination
            self.preferredPresentationBackgroundColor = preferredPresentationBackgroundColor
            self.hidesBottomBarWhenPushed = hidesBottomBarWhenPushed
        }

        var preferredPresentationBackgroundUIColor: UIColor? {
            preferredPresentationBackgroundColor?.toUIColor()
        }
    }
}

@available(iOS 14.0, *)
extension DestinationLinkTransition {
    /// The default presentation style of the `UINavigationController`.
    public static func `default`(
        options: DestinationLinkTransition.Options
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .default(options))
    }

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static func zoom(
        options: Options
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .zoom(options))
    }

    /// The zoom presentation style if available, otherwise a fallback transition style.
    public static func zoomIfAvailable(
        options: Options,
        otherwise fallback: DestinationLinkTransition = .default
    ) -> DestinationLinkTransition {
        if #available(iOS 18.0, *) {
            return .zoom(options: options)
        }
        return fallback
    }

    /// A custom presentation style.
    public static func custom<T: DestinationLinkTransitionRepresentable>(
        options: DestinationLinkTransition.Options,
        _ transition: T
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .representable(options, transition))
    }
}

@available(iOS 14.0, *)
extension DestinationLinkTransition {

    /// The matched geometry transition style.
    public static var matchedGeometry: DestinationLinkTransition {
        .matchedGeometry(.init())
    }

    /// The matched geometry transition style.
    public static func matchedGeometry(
        _ transitionOptions: MatchedGeometryPushTransition.Options,
        options: DestinationLinkTransition.Options = .init()
    ) -> DestinationLinkTransition {
        .asymmetric(
            push: MatchedGeometryPushTransition(options: transitionOptions),
            pop: .default,
            options: options
        )
    }

    /// The matched geometry transition style.
    public static func matchedGeometry(
        preferredCornerRadius: CGFloat? = nil,
        prefersScaleEffect: Bool = false,
        prefersZoomEffect: Bool = false,
        minimumScaleFactor: CGFloat = 0.5,
        initialOpacity: CGFloat = 1,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> DestinationLinkTransition {
        .matchedGeometry(
            .init(
                preferredFromCornerRadius: preferredCornerRadius,
                prefersScaleEffect: prefersScaleEffect,
                prefersZoomEffect: prefersZoomEffect,
                minimumScaleFactor: minimumScaleFactor,
                initialOpacity: initialOpacity
            ),
            options: .init(
                isInteractive: isInteractive,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
            )
        )
    }

    /// The matched geometry transition style.
    public static let matchedGeometryZoom: DestinationLinkTransition = .matchedGeometryZoom()

    /// The matched geometry transition style.
    public static func matchedGeometryZoom(
        preferredCornerRadius: CGFloat? = nil
    ) -> DestinationLinkTransition {
        .matchedGeometry(
            preferredCornerRadius: preferredCornerRadius,
            prefersScaleEffect: true,
            prefersZoomEffect: true,
            initialOpacity: 0
        )
    }
}

@available(iOS 14.0, *)
public struct MatchedGeometryPushTransition: DestinationLinkPushTransitionRepresentable {

    /// The transition options for a card transition.
    @frozen
    public struct Options {

        public var edges: Edge.Set
        public var preferredFromCornerRadius: CGFloat?
        public var preferredToCornerRadius: CGFloat?
        public var prefersScaleEffect: Bool
        public var prefersZoomEffect: Bool
        public var minimumScaleFactor: CGFloat
        public var initialOpacity: CGFloat

        public init(
            edges: Edge.Set = .all,
            preferredFromCornerRadius: CGFloat? = nil,
            preferredToCornerRadius: CGFloat? = nil,
            prefersScaleEffect: Bool = false,
            prefersZoomEffect: Bool = false,
            minimumScaleFactor: CGFloat = 0.5,
            initialOpacity: CGFloat = 1
        ) {
            self.edges = edges
            self.preferredFromCornerRadius = preferredFromCornerRadius
            self.preferredToCornerRadius = preferredToCornerRadius
            self.prefersScaleEffect = prefersScaleEffect
            self.prefersZoomEffect = prefersZoomEffect
            self.minimumScaleFactor = minimumScaleFactor
            self.initialOpacity = initialOpacity
        }
    }
    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        pushing toVC: UIViewController,
        from fromVC: UIViewController,
        context: Context
    ) -> MatchedGeometryPresentationControllerTransition? {

        let transition = MatchedGeometryPresentationControllerTransition(
            sourceView: context.sourceView,
            prefersScaleEffect: false,
            prefersZoomEffect: true,
            preferredFromCornerRadius: nil,
            preferredToCornerRadius: nil,
            initialOpacity: 0,
            isPresenting: true,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = false
        return transition
    }
}

@available(iOS 14.0, *)
extension DestinationLinkTransition {

    /// The slide transition style.
    public static var slide: DestinationLinkTransition {
        .slide(.init())
    }

    /// The slide transition style.
    public static func slide(
        _ transitionOptions: SlidePushTransition.Options,
        options: DestinationLinkTransition.Options = .init()
    ) -> DestinationLinkTransition {
        .custom(
            options: options,
            SlidePushTransition(options: transitionOptions)
        )
    }

    /// The slide transition style.
    public static func slide(
        initialOpacity: CGFloat = 1,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> DestinationLinkTransition {
        .matchedGeometry(
            .init(
                initialOpacity: initialOpacity
            ),
            options: .init(
                isInteractive: isInteractive,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
            )
        )
    }
}

@available(iOS 14.0, *)
public struct SlidePushTransition: DestinationLinkTransitionRepresentable {

    /// The transition options for a card transition.
    @frozen
    public struct Options {

        public var initialOpacity: CGFloat

        public init(
            initialOpacity: CGFloat = 1
        ) {
            self.initialOpacity = initialOpacity
        }
    }
    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        pushing toVC: UIViewController,
        from fromVC: UIViewController,
        context: Context
    ) -> SlidePushControllerTransition? {
        let transition = SlidePushControllerTransition(
            initialOpacity: options.initialOpacity,
            isPresenting: true,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = false
        return transition
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        popping fromVC: UIViewController,
        to toVC: UIViewController,
        context: Context
    ) -> SlidePushControllerTransition? {
        let transition = SlidePushControllerTransition(
            initialOpacity: options.initialOpacity,
            isPresenting: false,
            animation: context.transaction.animation
        )
        return transition
    }
}

@available(iOS 14.0, *)
open class SlidePushControllerTransition: InteractiveViewControllerTransition {

    public let initialOpacity: CGFloat

    public init(
        initialOpacity: CGFloat,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.initialOpacity = initialOpacity
        super.init(isPresenting: isPresenting, animation: animation)
    }

    open override func configureTransitionAnimator(
        using transitionContext: any UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let width = transitionContext.containerView.frame.width
        transitionContext.containerView.addSubview(toVC.view)
        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        toVC.view.transform = CGAffineTransform(
            translationX: isPresenting ? width : -width,
            y: 0
        )
        toVC.view.layoutIfNeeded()
        toVC.view.alpha = initialOpacity

        let fromVCTransform = CGAffineTransform(
            translationX: isPresenting ? -width : width,
            y: 0
        )

        animator.addAnimations { [initialOpacity] in
            toVC.view.transform = .identity
            toVC.view.alpha = 1
            fromVC.view.transform = fromVCTransform
            fromVC.view.alpha = initialOpacity
        }
        animator.addCompletion { animatingPosition in
            toVC.view.transform = .identity
            fromVC.view.transform = .identity
            switch animatingPosition {
            case .end:
                transitionContext.completeTransition(true)
            default:
                transitionContext.completeTransition(false)
            }
        }
    }
}

#endif
