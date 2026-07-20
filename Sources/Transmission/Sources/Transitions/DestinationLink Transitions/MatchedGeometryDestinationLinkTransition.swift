//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension DestinationLinkTransition {

    /// The matched geometry transition style.
    public static var matchedGeometry: DestinationLinkTransition {
        .matchedGeometry(.init())
    }

    /// The matched geometry transition style.
    public static func matchedGeometry(
        _ transitionOptions: MatchedGeometryDestinationLinkTransition.Options,
        options: DestinationLinkTransition.Options = .init()
    ) -> DestinationLinkTransition {
        .custom(
            options: options,
            MatchedGeometryDestinationLinkTransition(options: transitionOptions)
        )
    }

    /// The matched geometry transition style.
    public static func matchedGeometry(
        preferredFromCornerRadius: CornerRadiusOptions? = nil,
        prefersZoomEffect: Bool = false,
        initialOpacity: CGFloat = 1,
        sourceViewFrameTransform: SourceViewFrameTransform? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> DestinationLinkTransition {
        .matchedGeometry(
            .init(
                preferredFromCornerRadius: preferredFromCornerRadius,
                prefersZoomEffect: prefersZoomEffect,
                initialOpacity: initialOpacity,
                sourceViewFrameTransform: sourceViewFrameTransform
            ),
            options: .init(
                isInteractive: isInteractive,
                prefersPanGesturePop: true,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
            )
        )
    }

    /// The matched geometry transition style.
    public static let matchedGeometryZoom: DestinationLinkTransition = .matchedGeometryZoom()

    /// The matched geometry transition style.
    public static func matchedGeometryZoom(
        preferredFromCornerRadius: CornerRadiusOptions? = nil,
        sourceViewFrameTransform: SourceViewFrameTransform? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> DestinationLinkTransition {
        .matchedGeometry(
            preferredFromCornerRadius: preferredFromCornerRadius,
            prefersZoomEffect: true,
            initialOpacity: 0,
            sourceViewFrameTransform: sourceViewFrameTransform,
            isInteractive: isInteractive,
            preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
        )
    }
}

@available(iOS 14.0, *)
public struct MatchedGeometryDestinationLinkTransition: DestinationLinkTransitionRepresentable {

    /// The transition options for a matched geometry transition.
    @frozen
    public struct Options: @unchecked Sendable {

        public var preferredFromCornerRadius: CornerRadiusOptions?
        public var prefersZoomEffect: Bool
        public var initialOpacity: CGFloat
        public var sourceViewFrameTransform: SourceViewFrameTransform?

        public init(
            preferredFromCornerRadius: CornerRadiusOptions? = nil,
            prefersZoomEffect: Bool = false,
            initialOpacity: CGFloat = 1,
            sourceViewFrameTransform: SourceViewFrameTransform? = nil
        ) {
            self.preferredFromCornerRadius = preferredFromCornerRadius
            self.prefersZoomEffect = prefersZoomEffect
            self.initialOpacity = initialOpacity
            self.sourceViewFrameTransform = sourceViewFrameTransform
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
    ) -> MatchedGeometryNavigationControllerTransition? {

        let transition = MatchedGeometryNavigationControllerTransition(
            sourceView: context.sourceView,
            prefersScaleEffect: false,
            prefersZoomEffect: options.prefersZoomEffect,
            preferredFromCornerRadius: options.preferredFromCornerRadius,
            preferredToCornerRadius: nil,
            initialOpacity: options.initialOpacity,
            sourceViewFrameTransform: options.sourceViewFrameTransform,
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
    ) -> MatchedGeometryNavigationControllerTransition? {

        let transition = MatchedGeometryNavigationControllerTransition(
            sourceView: context.sourceView,
            prefersScaleEffect: false,
            prefersZoomEffect: options.prefersZoomEffect,
            preferredFromCornerRadius: options.preferredFromCornerRadius,
            preferredToCornerRadius: nil,
            initialOpacity: options.initialOpacity,
            sourceViewFrameTransform: options.sourceViewFrameTransform,
            isPresenting: false,
            animation: context.transaction.animation
        )
        return transition
    }
}

@available(iOS 14.0, *)
open class MatchedGeometryNavigationControllerTransition: NavigationControllerTransition {

    public weak var sourceView: UIView?
    public let prefersScaleEffect: Bool
    public let prefersZoomEffect: Bool
    public let preferredFromCornerRadius: CornerRadiusOptions?
    public let preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle?
    public let initialOpacity: CGFloat
    public let sourceViewFrameTransform: SourceViewFrameTransform?

    public init(
        sourceView: UIView?,
        prefersScaleEffect: Bool,
        prefersZoomEffect: Bool,
        preferredFromCornerRadius: CornerRadiusOptions?,
        preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle?,
        initialOpacity: CGFloat,
        sourceViewFrameTransform: SourceViewFrameTransform? = nil,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.prefersScaleEffect = prefersScaleEffect
        self.prefersZoomEffect = prefersZoomEffect
        self.preferredFromCornerRadius = preferredFromCornerRadius
        self.preferredToCornerRadius = preferredToCornerRadius
        self.initialOpacity = initialOpacity
        self.sourceViewFrameTransform = sourceViewFrameTransform
        self.sourceView = sourceView
        super.init(
            isPresenting: isPresenting,
            animation: animation
        )
    }

    open override func configureTransitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {
        let transition = MatchedGeometryViewControllerTransitionAnimator(
            sourceView: sourceView,
            prefersScaleEffect: prefersScaleEffect,
            prefersZoomEffect: prefersZoomEffect,
            preferredFromCornerRadius: preferredFromCornerRadius,
            preferredToCornerRadius: preferredToCornerRadius,
            initialOpacity: initialOpacity
        )
        transition.animateTransition(with: animator, using: transitionContext, isPresenting: isPresenting)
    }
}

#endif
