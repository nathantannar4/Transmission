//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
open class PresentationControllerTransition: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {

    public let isPresenting: Bool
    public let animation: Animation?
    private var animator: UIViewPropertyAnimator?

    private var transitionDuration: CGFloat = 0
    open override var duration: CGFloat {
        transitionDuration
    }

    public init(
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.isPresenting = isPresenting
        self.animation = animation
        super.init()
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    open override func startInteractiveTransition(
        _ transitionContext: UIViewControllerContextTransitioning
    ) {
        super.startInteractiveTransition(transitionContext)
        transitionDuration = transitionDuration(using: transitionContext)
    }

    open func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        guard transitionContext?.isAnimated == true else { return 0 }
        return animation?.duration ?? 0.35
    }

    public func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        transitionDuration = transitionDuration(using: transitionContext)
        let animator = makeTransitionAnimatorIfNeeded(using: transitionContext)
        let delay = animation?.delay ?? 0
        if let presentationController = transitionContext.viewController(forKey: isPresenting ? .to : .from)?.presentationController as? PresentationController {
            presentationController.layoutShadowView()
        }
        animator.startAnimation(afterDelay: delay)

        if !transitionContext.isAnimated {
            animator.stopAnimation(false)
            animator.finishAnimation(at: .end)
        }
    }

    open func animationEnded(_ transitionCompleted: Bool) {
        animator = nil
    }

    public func interruptibleAnimator(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating {
        let animator = makeTransitionAnimatorIfNeeded(using: transitionContext)
        return animator
    }

    open override func responds(to aSelector: Selector!) -> Bool {
        let responds = super.responds(to: aSelector)
        if aSelector == #selector(interruptibleAnimator(using:)) {
            return responds && wantsInteractiveStart
        }
        return responds
    }

    private func makeTransitionAnimatorIfNeeded(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewPropertyAnimator {
        if let animator = animator {
            return animator
        }
        let animator = transitionAnimator(using: transitionContext)
        self.animator = animator
        return animator
    }

    open func transitionAnimator(
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

        if isPresenting {
            let frame = transitionContext.finalFrame(for: presented)
            transitionContext.containerView.addSubview(presented.view)
            presented.view.frame = frame
            let transform = CGAffineTransform(
                translationX: 0,
                y: frame.size.height + transitionContext.containerView.safeAreaInsets.bottom
            )
            presented.view.transform = transform
            animator.addAnimations {
                presented.view.transform = .identity
            }
        } else {
            if presenting.view.superview == nil {
                transitionContext.containerView.insertSubview(presenting.view, at: 0)
                presenting.view.frame = transitionContext.finalFrame(for: presenting)
                presenting.view.layoutIfNeeded()
            }
            let frame = transitionContext.finalFrame(for: presented)
            let dy = transitionContext.containerView.frame.height - frame.origin.y
            let transform = CGAffineTransform(
                translationX: 0,
                y: dy
            )
            animator.addAnimations {
                presented.view.transform = transform
            }
        }
        animator.addCompletion { animatingPosition in
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
