//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

/// A presentation controller that presents the view from a source view rect
@available(iOS 14.0, *)
open class MatchedGeometryPresentationController: InteractivePresentationController {

    public var preferredCornerRadius: CGFloat?

    public var minimumScaleFactor: CGFloat

    open override var wantsInteractiveDismissal: Bool {
        return true
    }

    public init(
        edges: Edge.Set,
        preferredCornerRadius: CGFloat?,
        minimumScaleFactor: CGFloat,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.preferredCornerRadius = preferredCornerRadius
        self.minimumScaleFactor = minimumScaleFactor
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
        let dz = sqrt(pow(translation.y, 2) + pow(translation.x, 2))
        let magnitude = sqrt(pow(velocity.y, 2) + pow(velocity.x, 2))
        let canFinish = (dz >= 200 && magnitude > 0) || magnitude >= 1000
        guard canFinish else { return false }
        return super.dismissalTransitionShouldBegin(
            translation: translation,
            delta: delta,
            velocity: velocity
        )
    }

    open override func transformPresentedView(transform: CGAffineTransform) {
        super.transformPresentedView(transform: transform)

        if transform == .identity {
            presentedViewController.view.layer.cornerRadius = 0
        } else {
            let cornerRadius = transform.d * UIScreen.main.displayCornerRadius
            presentedViewController.view.layer.cornerRadius = max(preferredCornerRadius ?? 0, cornerRadius)
        }
    }

    open override func presentedViewTransform(for translation: CGPoint) -> CGAffineTransform {
        let frame = frameOfPresentedViewInContainerView
        let dx = frictionCurve(translation.x, distance: frame.width, coefficient: 1)
        let dy = frictionCurve(translation.y, distance: frame.height, coefficient: 0.5)
        let scale = max(minimumScaleFactor, min(1 - (abs(dx) / frame.width), 1 - (abs(dy) / frame.height)))
        return CGAffineTransform(translationX: dx, y: dy * 0.25)
            .translatedBy(x: (1 - scale) * 0.5 * frame.width, y: (1 - scale) * 0.5 * frame.height)
            .scaledBy(x: scale, y: scale)
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        presentedViewController.view.clipsToBounds = true
        if let preferredCornerRadius {
            presentedViewController.view.layer.cornerRadius = preferredCornerRadius
        }
        dimmingView.isHidden = false
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            presentedViewController.view.layer.cornerRadius = 0
        }
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentedViewController.view.layer.cornerRadius = UIScreen.main.displayCornerRadius
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            presentedViewController.view.layer.cornerRadius = 0
        }
    }

    open override func transitionAlongsidePresentation(isPresented: Bool) {
        super.transitionAlongsidePresentation(isPresented: isPresented)
        presentedViewController.view.layer.cornerRadius = isPresented ? UIScreen.main.displayCornerRadius : (preferredCornerRadius ?? 0)
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
///     let transition = MatchedGeometryPresentationControllerTransition(
///         sourceView: sourceView,
///         prefersScaleEffect: options.prefersScaleEffect,
///         fromOpacity: options.initialOpacity,
///         isPresenting: true,
///         animation: animation
///     )
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
///     let transition = MatchedGeometryPresentationControllerTransition(
///         sourceView: sourceView,
///         prefersScaleEffect: options.prefersScaleEffect,
///         fromOpacity: options.initialOpacity,
///         isPresenting: false,
///         animation: animation
///     )
///     transition.wantsInteractiveStart = options.options.isInteractive && presentationController.wantsInteractiveTransition
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
open class MatchedGeometryPresentationControllerTransition: PresentationControllerTransition {

    public let prefersScaleEffect: Bool
    public let fromOpacity: CGFloat
    public weak var sourceView: UIView?

    public init(
        sourceView: UIView,
        prefersScaleEffect: Bool,
        fromOpacity: CGFloat,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.prefersScaleEffect = prefersScaleEffect
        self.fromOpacity = fromOpacity
        super.init(isPresenting: isPresenting, animation: animation)
        self.sourceView = sourceView
    }

    public override func transitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewPropertyAnimator {

        let animator = UIViewPropertyAnimator(animation: animation) ?? UIViewPropertyAnimator(duration: duration, curve: completionCurve)

        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to)
        else {
            transitionContext.completeTransition(false)
            return animator
        }

        let sourceViewController = sourceView?.viewController
        let prefersScaleEffect = prefersScaleEffect
        let fromOpacity = fromOpacity
        let isPresenting = isPresenting
        let hostingController = presented as? AnyHostingController

        let oldValue = hostingController?.disableSafeArea ?? false
        hostingController?.disableSafeArea = true

        let scaleEffect = CGAffineTransform(scaleX: 0.9, y: 0.9)
        if prefersScaleEffect, !isPresenting {
            sourceViewController?.view.transform = .identity
        }

        let sourceFrame = sourceView.map {
            $0.convert($0.frame, to: transitionContext.containerView)
        } ?? transitionContext.containerView.frame

        if prefersScaleEffect, !isPresenting {
            sourceViewController?.view.transform = scaleEffect
        }

        let presentedFrame = isPresenting
            ? transitionContext.finalFrame(for: presented)
            : transitionContext.initialFrame(for: presented)
        if isPresenting {
            presented.view.alpha = fromOpacity
            transitionContext.containerView.addSubview(presented.view)
            presented.view.frame = sourceFrame
            presented.view.layoutIfNeeded()
            hostingController?.render()
        } else if presenting.view.superview == nil {
            transitionContext.containerView.insertSubview(presenting.view, belowSubview: presented.view)
        }
        if !isPresenting, prefersScaleEffect {
            sourceViewController?.view.transform = scaleEffect
        }

        animator.addAnimations {
            if isPresenting {
                hostingController?.disableSafeArea = oldValue
            }
            presented.view.alpha = isPresenting ? 1 : fromOpacity
            presented.view.frame = isPresenting ? presentedFrame : sourceFrame
            presented.view.layoutIfNeeded()
            if prefersScaleEffect {
                sourceViewController?.view.transform = isPresenting ? scaleEffect : .identity
            }
        }
        animator.addCompletion { animatingPosition in
            hostingController?.disableSafeArea = oldValue
            switch animatingPosition {
            case .end:
                transitionContext.completeTransition(true)
            default:
                transitionContext.completeTransition(false)
            }
        }
        return animator
    }
}

#endif
