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

    public var prefersZoomEffect: Bool

    public var minimumScaleFactor: CGFloat

    open override var wantsInteractiveDismissal: Bool {
        return true
    }

    public init(
        edges: Edge.Set = .all,
        preferredCornerRadius: CGFloat? = nil,
        minimumScaleFactor: CGFloat = 0.5,
        prefersZoomEffect: Bool = false,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.preferredCornerRadius = preferredCornerRadius
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
        guard panGesture.state == .ended else {
            return false
        }
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
        if prefersZoomEffect {
            if transform.isIdentity {
                presentedViewController.view.layer.cornerRadius = 0
            } else {
                presentedViewController.view.layer.cornerRadius = UIScreen.main.displayCornerRadius
            }
            presentedViewController.view.transform = transform
            layoutShadowView()

        } else {
            super.transformPresentedView(transform: transform)

            if transform.isIdentity {
                presentedViewController.view.layer.cornerRadius = 0
                updateShadow(progress: 0)
            } else {
                let progress = prefersZoomEffect ? 0 : max(0, min(transform.d, 1))
                let cornerRadius = progress * UIScreen.main.displayCornerRadius
                presentedViewController.view.layer.cornerRadius = max(preferredCornerRadius ?? 0, cornerRadius)
                updateShadow(progress: progress)
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

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        if let preferredCornerRadius {
            presentedViewController.view.layer.cornerRadius = preferredCornerRadius
        }
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        presentedViewController.view.layer.cornerRadius = 0
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentedViewController.view.layer.cornerRadius = UIScreen.main.displayCornerRadius
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        presentedViewController.view.layer.cornerRadius = 0
    }

    open override func transitionAlongsidePresentation(isPresented: Bool) {
        super.transitionAlongsidePresentation(isPresented: isPresented)
        presentedViewController.view.layer.cornerRadius = isPresented ? UIScreen.main.displayCornerRadius : (preferredCornerRadius ?? 0)
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
///     let transition = MatchedGeometryPresentationControllerTransition(
///         sourceView: sourceView,
///         prefersScaleEffect: options.prefersScaleEffect,
///         prefersZoomEffect: options.prefersZoomEffect,
///         preferredCornerRadius: options.preferredCornerRadius,
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
///         prefersZoomEffect: options.prefersZoomEffect,
///         preferredCornerRadius: options.preferredCornerRadius,
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
    public let prefersZoomEffect: Bool
    public let preferredCornerRadius: CGFloat?
    public let fromOpacity: CGFloat
    public weak var sourceView: UIView?

    public init(
        sourceView: UIView,
        prefersScaleEffect: Bool,
        prefersZoomEffect: Bool,
        preferredCornerRadius: CGFloat?,
        fromOpacity: CGFloat,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.prefersScaleEffect = prefersScaleEffect
        self.prefersZoomEffect = prefersZoomEffect
        self.preferredCornerRadius = preferredCornerRadius
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

        let sourceView = sourceView
        let sourceViewController = sourceView?.viewController
        let prefersScaleEffect = prefersScaleEffect
        let prefersZoomEffect = prefersZoomEffect
        let fromOpacity = fromOpacity
        let isPresenting = isPresenting

        lazy var hostingController: AnyHostingController? = {
            if prefersZoomEffect {
                return nil
            }
            return presented as? AnyHostingController
        }()

        lazy var portalView: PortalView? = {
            if prefersZoomEffect {
                let portalView = PortalView(sourceView: presented.view)
                portalView?.hidesSourceView = true
                return portalView
            }
            return nil
        }()

        lazy var window: UIWindow? = {
            if prefersScaleEffect {
                if sourceViewController?.parent == nil {
                    if let window = sourceViewController?.view.window {
                        return window
                    }
                }
            }
            return nil
        }()

        let scaleEffect = CGAffineTransform(scaleX: 0.9, y: 0.9)
        let cornerRadius = preferredCornerRadius ?? UIScreen.main._displayCornerRadius
        if prefersScaleEffect, !isPresenting {
            sourceViewController?.view.transform = .identity
            sourceViewController?.view.layer.cornerRadius = cornerRadius
        }

        let oldValue = hostingController?.disableSafeArea ?? false
        hostingController?.disableSafeArea = true

        if prefersScaleEffect {
            sourceViewController?.view.layer.masksToBounds = true
            if window?.backgroundColor == nil {
                window?.backgroundColor = sourceViewController?.view.backgroundColor
            }
        }

        let sourceFrame = sourceView.map {
            $0.convert($0.frame, to: transitionContext.containerView)
        } ?? transitionContext.containerView.frame

        let presentedFrame = isPresenting
            ? transitionContext.finalFrame(for: presented)
        : (presented.view.transform.isIdentity ? presented.view.frame : transitionContext.initialFrame(for: presented))

        if prefersScaleEffect, !isPresenting {
            sourceViewController?.view.transform = scaleEffect
        }

        if isPresenting {
            transitionContext.containerView.addSubview(presented.view)

            if prefersZoomEffect {
                presented.view.frame = presentedFrame
                sourceView?.alpha = 1 - fromOpacity
                if let portalView {
                    transitionContext.containerView.addSubview(portalView)
                }
                portalView?.frame = presentedFrame
                portalView?.alpha = fromOpacity
                portalView?.transform = CGAffineTransform(to: presentedFrame, from: sourceFrame)
                if let presentationController = presented.presentationController as? PresentationController {
                    presentationController.shadowView.preferredSourceView = portalView
                }

            } else {
                presented.view.frame = sourceFrame
                presented.view.alpha = fromOpacity
                presented.view.layoutIfNeeded()
                hostingController?.render()
            }

        } else if presenting.view.superview == nil {
            transitionContext.containerView.insertSubview(presenting.view, belowSubview: presented.view)
        }

        if !isPresenting, prefersScaleEffect {
            sourceViewController?.view.transform = scaleEffect
        }

        if !isPresenting, prefersZoomEffect, let portalView {
            transitionContext.containerView.addSubview(portalView)
            portalView.frame = presentedFrame
            portalView.transform = presented.view.transform
            if let presentationController = presented.presentationController as? PresentationController {
                presentationController.shadowView.preferredSourceView = portalView
            }
        }
        
        animator.addAnimations {
            if isPresenting {
                hostingController?.disableSafeArea = oldValue
            }
            if prefersZoomEffect {
                portalView?.transform = isPresenting ? .identity : CGAffineTransform(to: presentedFrame, from: sourceFrame)
            } else {
                presented.view.frame = isPresenting ? presentedFrame : sourceFrame
                presented.view.layoutIfNeeded()
            }

            if prefersScaleEffect {
                sourceViewController?.view.layer.cornerRadius = isPresenting ? cornerRadius : 0
                sourceViewController?.view.transform = isPresenting ? scaleEffect : .identity
            }
        }
        animator.addAnimations({
            if prefersZoomEffect {
                sourceView?.alpha = isPresenting ? 0 : 1 - fromOpacity
                portalView?.alpha = isPresenting ? 1 : fromOpacity
            } else {
                presented.view.alpha = isPresenting ? 1 : fromOpacity
            }
        }, delayFactor: isPresenting ? 0 : 0.25)

        animator.addCompletion { animatingPosition in
            hostingController?.disableSafeArea = oldValue
            portalView?.removeFromSuperview()
            if prefersScaleEffect, !isPresenting {
                sourceViewController?.view.layer.masksToBounds = false
                window?.backgroundColor = nil
            }
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
