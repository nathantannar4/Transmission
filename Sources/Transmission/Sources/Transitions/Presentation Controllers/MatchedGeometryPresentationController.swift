//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

/// A presentation controller that presents the view from a source view rect
@available(iOS 14.0, *)
open class MatchedGeometryPresentationController: InteractivePresentationController {

    public var prefersZoomEffect: Bool

    public var minimumScaleFactor: CGFloat

    open override var wantsInteractiveDismissal: Bool {
        return true
    }

    public init(
        edges: Edge.Set = .all,
        minimumScaleFactor: CGFloat = 0.5,
        prefersZoomEffect: Bool = false,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.minimumScaleFactor = minimumScaleFactor
        self.prefersZoomEffect = prefersZoomEffect
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
        self.edges = edges
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
        if prefersZoomEffect {
            if transform.isIdentity {
                presentedViewController.view.layer.cornerRadius = 0
            } else {
                presentedViewController.view.layer.cornerRadius = UIScreen.main.displayCornerRadius()
            }
            presentedViewController.view.transform = transform
            layoutBackgroundViews()

        } else {
            super.transformPresentedView(transform: transform)

            if transform.isIdentity {
                presentedViewController.view.layer.cornerRadius = 0
            } else {
                let progress = prefersZoomEffect ? 0 : max(0, min(transform.d, 1))
                let cornerRadius = progress * UIScreen.main.displayCornerRadius()
                presentedViewController.view.layer.cornerRadius = cornerRadius
            }
        }
    }

    open override func presentedViewTransform(for translation: CGPoint) -> CGAffineTransform {
        let frame = frameOfPresentedViewInContainerView
        if prefersZoomEffect {
            let dx = frictionCurve(translation.x, distance: frame.width, coefficient: 0.4)
            let dy = frictionCurve(translation.y, distance: frame.height, coefficient: 0.3)
            let scale = min(max(1 - dy / frame.width, minimumScaleFactor), 1)
            return CGAffineTransform(translationX: dx, y: min(dy, frame.width * minimumScaleFactor))
                .scaledBy(x: scale, y: scale)
        } else {
            let dx = frictionCurve(translation.x, distance: frame.width, coefficient: 1)
            let dy = frictionCurve(translation.y, distance: frame.height, coefficient: 0.5)
            let scale = max(minimumScaleFactor, min(1 - (abs(dx) / frame.width), 1 - (abs(dy) / frame.height)))
            return CGAffineTransform(translationX: dx, y: dy * 0.25)
                .translatedBy(x: (1 - scale) * 0.5 * frame.width, y: (1 - scale) * 0.5 * frame.height)
                .scaledBy(x: scale, y: scale)
        }
    }

    open override func updateShadow(progress: Double) {
        super.updateShadow(progress: progress)
        dimmingView.isHidden = presentedViewShadow.shadowOpacity > 0
    }
}

/// An interactive transition built for the ``MatchedGeometryPresentationController``.
///
/// ```
/// func animationController(
///     forPresented presented: UIViewController,
///     presenting: UIViewController,
///     source: UIViewController
/// ) -> UIViewControllerAnimatedTransitioning? {
///     let transition = MatchedGeometryPresentationControllerTransition(...)
///     transition.wantsInteractiveStart = false
///     return transition
/// }
///
/// func animationController(
///     forDismissed dismissed: UIViewController
/// ) -> UIViewControllerAnimatedTransitioning? {
///     guard let presentationController = dismissed.presentationController as? MatchedGeometryPresentationController else {
///         return nil
///     }
///     let transition = MatchedGeometryPresentationControllerTransition(...)
///     transition.wantsInteractiveStart = presentationController.wantsInteractiveTransition
///     presentationController.transition(with: transition)
///     return transition
/// }
///
/// func interactionControllerForDismissal(
///     using animator: UIViewControllerAnimatedTransitioning
/// ) -> UIViewControllerInteractiveTransitioning? {
///     return animator as? MatchedGeometryPresentationControllerTransition
/// }
/// ```
///
@available(iOS 14.0, *)
open class MatchedGeometryPresentationControllerTransition: MatchedGeometryViewControllerTransition {

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
