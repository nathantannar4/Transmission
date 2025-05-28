//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
open class InteractiveViewControllerTransition: ViewControllerTransition {

    public override init(isPresenting: Bool, animation: Animation?) {
        super.init(isPresenting: isPresenting, animation: animation)
        wantsInteractiveStart = true
    }
}

@available(iOS 14.0, *)
open class ViewControllerTransition: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {

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
        wantsInteractiveStart = false
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    open override func startInteractiveTransition(
        _ transitionContext: UIViewControllerContextTransitioning
    ) {
        super.startInteractiveTransition(transitionContext)
        if let presenting = transitionContext.viewController(forKey: isPresenting ? .to : .from) {
            presenting.transitionReaderAnimation = animation
        }
        transitionDuration = transitionDuration(using: transitionContext)
    }

    open func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        guard transitionContext?.isAnimated == true else { return 0 }
        return animation?.duration(defaultDuration: 0.35) ?? 0.35
    }

    public func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        transitionDuration = transitionDuration(using: transitionContext)
        let animator = makeTransitionAnimatorIfNeeded(using: transitionContext)
        let delay = animation?.delay ?? 0
        animatedStarted(transitionContext: transitionContext)
        animator.startAnimation(afterDelay: delay)

        if !transitionContext.isAnimated {
            animator.stopAnimation(false)
            animator.finishAnimation(at: .end)
        }
    }

    open func animatedStarted(
        transitionContext: UIViewControllerContextTransitioning
    ) {
    }

    open func animationEnded(
        _ transitionCompleted: Bool
    ) {
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
        let animator = UIViewPropertyAnimator(
            animation: animation,
            defaultDuration: duration,
            defaultCompletionCurve: completionCurve
        )
        configureTransitionAnimator(using: transitionContext, animator: animator)
        self.animator = animator
        return animator
    }

    open func configureTransitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {

        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let isPresenting = isPresenting
        if isPresenting {
            presented.view.alpha = 0
            let presentedFrame = transitionContext.finalFrame(for: presented)
            transitionContext.containerView.addSubview(presented.view)
            presented.view.frame = presentedFrame
            presented.view.layoutIfNeeded()
        } else {
            if presenting.view.superview == nil {
                transitionContext.containerView.insertSubview(presenting.view, at: 0)
                presenting.view.frame = transitionContext.finalFrame(for: presenting)
                presenting.view.layoutIfNeeded()
            }
            presented.view.layoutIfNeeded()
        }
        animator.addAnimations {
            presented.view.alpha = isPresenting ? 1 : 0
        }
        animator.addCompletion { animatingPosition in
            switch animatingPosition {
            case .end:
                transitionContext.completeTransition(true)
            default:
                transitionContext.completeTransition(false)
            }
        }
    }
}

extension UIViewControllerContextTransitioning {

    func presentationController(isPresenting: Bool) -> UIPresentationController? {
        viewController(forKey: isPresenting ? .to : .from)?._activePresentationController
    }
}

#endif
