//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
class MatchedGeometryPresentationController: InteractivePresentationController {

    var preferredCornerRadius: CGFloat?

    open override var wantsInteractiveDismissal: Bool {
        return true
    }

    init(
        edges: Edge.Set,
        preferredCornerRadius: CGFloat?,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.preferredCornerRadius = preferredCornerRadius
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
        self.edges = edges
    }

    override func dismissalTransitionShouldBegin(
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

    override func transformPresentedView(transform: CGAffineTransform) {
        super.transformPresentedView(transform: transform)

        let cornerRadius = transform.d * UIScreen.main.displayCornerRadius
        presentedViewController.view.layer.cornerRadius = max(preferredCornerRadius ?? 0, cornerRadius)
    }

    override func presentedViewTransform(for translation: CGPoint) -> CGAffineTransform {
        let frame = frameOfPresentedViewInContainerView
        let distance = frame.height
        let dx = frictionCurve(translation.x, distance: distance)
        let dy = frictionCurve(translation.y, distance: distance)
        let scale = min(1 - (abs(dx) / distance), 1 - (abs(dy) / distance))
        return CGAffineTransform(translationX: dx, y: dy)
            .translatedBy(x: (1 - scale) * 0.5 * frame.width, y: (1 - scale) * 0.5 * distance)
            .scaledBy(x: scale, y: scale)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        presentedViewController.view.clipsToBounds = true
        if let preferredCornerRadius {
            presentedViewController.view.layer.cornerRadius = preferredCornerRadius
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            presentedViewController.view.layer.cornerRadius = 0
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentedViewController.view.layer.cornerRadius = UIScreen.main.displayCornerRadius
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            presentedViewController.view.layer.cornerRadius = 0
        }
    }

    override func transitionAlongsidePresentation(isPresented: Bool) {
        super.transitionAlongsidePresentation(isPresented: isPresented)
        presentedViewController.view.layer.cornerRadius = isPresented ? UIScreen.main.displayCornerRadius : (preferredCornerRadius ?? 0)
    }
}

@available(iOS 14.0, *)
class MatchedGeometryTransition: PresentationControllerTransition {

    weak var sourceView: UIView?

    init(
        sourceView: UIView,
        isPresenting: Bool,
        animation: Animation?
    ) {
        super.init(isPresenting: isPresenting, animation: animation)
        self.sourceView = sourceView
    }

    override func transitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewPropertyAnimator {

        let animator = UIViewPropertyAnimator(animation: animation) ?? UIViewPropertyAnimator(duration: duration, curve: completionCurve)

        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from)
        else {
            transitionContext.completeTransition(false)
            return animator
        }

        let isPresenting = isPresenting
        let hostingController = presented as? AnyHostingController

        let oldValue = hostingController?.disableSafeArea ?? false
        hostingController?.disableSafeArea = true

        let sourceFrame = sourceView.map {
            $0.convert($0.frame, to: transitionContext.containerView)
        } ?? transitionContext.containerView.frame
        let presentedFrame = isPresenting
            ? transitionContext.finalFrame(for: presented)
            : transitionContext.initialFrame(for: presented)
        if isPresenting {
            transitionContext.containerView.addSubview(presented.view)
            presented.view.frame = sourceFrame
            presented.view.layoutIfNeeded()
            hostingController?.render()
        }

        animator.addAnimations {
            if isPresenting {
                hostingController?.disableSafeArea = oldValue
            }
            presented.view.frame = isPresenting ? presentedFrame : sourceFrame
            presented.view.layoutIfNeeded()
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

extension CGAffineTransform {
    init(from source: CGRect, to destination: CGRect) {
        self = CGAffineTransform.identity
            .translatedBy(x: destination.midX - source.midX, y: destination.midY - source.midY)
            .scaledBy(x: destination.width / source.width, y: destination.height / source.height)
    }
}

#endif
