//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

public struct CrossDissolveTransitionAnimator: ViewControllerTransitionAnimator {

    public let transform: CGAffineTransform
    public let fromCornerRadius: CornerRadiusOptions?
    public let toCornerRadius: CornerRadiusOptions?

    public init(
        transform: CGAffineTransform,
        fromCornerRadius: CornerRadiusOptions?,
        toCornerRadius: CornerRadiusOptions?,
    ) {
        self.transform = transform
        self.fromCornerRadius = fromCornerRadius
        self.toCornerRadius = toCornerRadius
    }

    public func animateTransition(
        with animator: UIViewPropertyAnimator,
        using transitionContext: UIViewControllerContextTransitioning,
        isPresenting: Bool
    ) {
        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to),
            let presentedView = transitionContext.view(forKey: isPresenting ? .to : .from) ?? presented.view,
            let presentingView = transitionContext.view(forKey: isPresenting ? .from : .to) ?? presenting.view
        else {
            transitionContext.completeTransition(false)
            return
        }

        let fromCornerRadius = fromCornerRadius
        let toCornerRadius = toCornerRadius ?? (isPresenting && fromCornerRadius != nil ? .identity : nil)

        if isPresenting {
            presentedView.alpha = 0
            var presentedFrame = transitionContext.finalFrame(for: presented)
            if presentedView.superview == nil {
                transitionContext.containerView.addSubview(presentedView)
            }
            presentedView.frame = presentedFrame
            presentedView.layoutIfNeeded()

            animateAlongsideTransitionReader(
                using: transitionContext,
                isPresenting: isPresenting,
                presentedFrame: &presentedFrame
            )

            presentedView.transform = transform
            fromCornerRadius?.apply(to: presentedView)
            animator.addAnimations {
                presentedView.alpha = 1
                presentedView.transform = .identity
                toCornerRadius?.apply(to: presentedView)
            }
        } else {
            if presentingView.superview == nil {
                transitionContext.containerView.insertSubview(presentingView, at: 0)
                presentingView.frame = transitionContext.finalFrame(for: presenting)
                presentingView.layoutIfNeeded()
            }
            presentedView.layoutIfNeeded()

            let transform = transform
            toCornerRadius?.apply(to: presentedView)
            animator.addAnimations {
                presentedView.alpha = 0
                presentedView.transform = transform
                fromCornerRadius?.apply(to: presentedView)
            }
        }
        animator.addCompletion { animatingPosition in
            if fromCornerRadius != nil || toCornerRadius != nil {
                CornerRadiusOptions.identity.apply(to: presentedView)
            }
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
