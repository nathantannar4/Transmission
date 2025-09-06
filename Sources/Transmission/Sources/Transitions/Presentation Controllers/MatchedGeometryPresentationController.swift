//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

/// A presentation controller that presents the view from a source view rect
@available(iOS 14.0, *)
open class MatchedGeometryPresentationController: InteractivePresentationController {

    public var minimumScaleFactor: CGFloat

    open override var wantsInteractiveDismissal: Bool {
        return true
    }

    public init(
        edges: Edge.Set = .all,
        minimumScaleFactor: CGFloat = 0.5,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.minimumScaleFactor = minimumScaleFactor
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
        self.edges = edges
        dimmingView.isHidden = false
    }

    open override func dismissalTransitionShouldBegin(
        translation: CGPoint,
        delta: CGPoint,
        velocity: CGPoint
    ) -> Bool {
        var shouldBegin = false
        if !shouldBegin, edges.contains(.bottom), translation.y > 0 {
            shouldBegin = (translation.y >= UIGestureRecognizer.zoomGestureActivationThreshold.height && velocity.y >= 0) || velocity.y >= 1000
        }
        if !shouldBegin, edges.contains(.top), translation.y < 0 {
            shouldBegin = (abs(translation.y) >= UIGestureRecognizer.zoomGestureActivationThreshold.height && velocity.y <= 0) || velocity.y <= -1000
        }
        if !shouldBegin, edges.contains(.leading), translation.x < 0 {
            shouldBegin = (abs(translation.x) >= UIGestureRecognizer.zoomGestureActivationThreshold.width && velocity.x <= 0) || velocity.x <= -1000
        }
        if !shouldBegin, edges.contains(.trailing), translation.x > 0 {
            shouldBegin = (translation.x >= UIGestureRecognizer.zoomGestureActivationThreshold.height && velocity.x >= 0) || velocity.x >= 1000
        }
        return shouldBegin
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        presentedViewController.view.layer.cornerCurve = .continuous
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            presentedViewController.view.layer.cornerRadius = 0
        }
    }

    open override func transformPresentedView(transform: CGAffineTransform) {
        super.transformPresentedView(transform: transform)
        if transform.isIdentity {
            presentedViewController.view.layer.cornerRadius = 0
        } else {
            let progress = max(0, min(transform.d, 1))
            let cornerRadius = progress * UIScreen.main.displayCornerRadius()
            presentedViewController.view.layer.cornerRadius = cornerRadius
        }
    }

    open override func presentedViewTransform(for translation: CGPoint) -> CGAffineTransform {
        let frame = frameOfPresentedViewInContainerView
        let dx = frictionCurve(translation.x, distance: frame.width, coefficient: 0.35)
        let dy = frictionCurve(translation.y, distance: frame.height, coefficient: 1)
        let scale = min(max(minimumScaleFactor, 1 - (dy / frame.height)), 1)
        return CGAffineTransform(translationX: dx, y: dy * 0.25)
            .translatedBy(x: (1 - scale) * 0.5 * frame.width, y: (1 - scale) * 0.5 * frame.height)
            .scaledBy(x: scale, y: scale)
    }
}

/// An interactive transition built for the ``MatchedGeometryPresentationController``.
@available(iOS 14.0, *)
open class MatchedGeometryPresentationControllerTransition: MatchedGeometryViewControllerTransition {

    open override var isInterruptible: Bool {
        return false
    }

    public override init(
        sourceView: UIView?,
        prefersScaleEffect: Bool,
        prefersZoomEffect: Bool,
        preferredFromCornerRadius: CornerRadiusOptions?,
        preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle?,
        initialOpacity: CGFloat,
        isPresenting: Bool,
        animation: Animation?
    ) {
        super.init(
            sourceView: sourceView,
            prefersScaleEffect: prefersScaleEffect,
            prefersZoomEffect: prefersZoomEffect,
            preferredFromCornerRadius: preferredFromCornerRadius,
            preferredToCornerRadius: preferredToCornerRadius,
            initialOpacity: initialOpacity,
            isPresenting: isPresenting,
            animation: animation
        )
        wantsInteractiveStart = true
    }

    open override func animatedStarted(
        transitionContext: UIViewControllerContextTransitioning
    ) {
        super.animatedStarted(transitionContext: transitionContext)

        if let presentationController = transitionContext.presentationController(isPresenting: isPresenting) as? PresentationController {
            presentationController.layoutBackgroundViews()
        }
    }
}

#endif
