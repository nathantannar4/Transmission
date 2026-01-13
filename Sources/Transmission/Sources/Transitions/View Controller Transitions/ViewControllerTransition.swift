//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
@MainActor @preconcurrency
open class ViewControllerTransition: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {

    public let isPresenting: Bool
    public var animation: Animation?
    private var animator: UIViewPropertyAnimator?

    private var transitionDuration: CGFloat = 0
    open override var duration: CGFloat {
        transitionDuration
    }
    
    open var isInterruptible: Bool {
        wantsInteractiveStart || (animation?.delay ?? 0) == 0
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
        transitionDuration = transitionDuration(using: transitionContext)
        super.startInteractiveTransition(transitionContext)
        animatedStarted(transitionContext: transitionContext)
        if let presenting = transitionContext.viewController(forKey: isPresenting ? .to : .from) {
            presenting.transitionReaderAnimation = animation
        }
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
        animatedStarted(transitionContext: transitionContext)

        if transitionContext.isAnimated {
            let delay = animation?.delay ?? 0
            animator.startAnimation(afterDelay: delay)
        } else {
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

    open override func pause() {
        super.pause()
        guard isInterruptible, animator?.isRunning == true else { return }
        animator?.pauseAnimation()
    }

    open override func update(_ percentComplete: CGFloat) {
        super.update(percentComplete)
        guard isInterruptible, animator?.fractionComplete != percentComplete else { return }
        animator?.fractionComplete = percentComplete
    }

    open override func finish() {
        super.finish()
        guard isInterruptible, animator?.isRunning == false else { return }
        if animator?.fractionComplete == 1, animator?.state == .active {
            animator?.stopAnimation(false)
            animator?.finishAnimation(at: .end)
        } else {
            animator?.continueAnimation(withTimingParameters: timingCurve, durationFactor: completionSpeed)
        }
    }

    open override func cancel() {
        super.cancel()
        guard isInterruptible, animator?.isRunning == false else { return }
        if animator?.fractionComplete == 0, animator?.state == .active {
            animator?.stopAnimation(false)
            animator?.finishAnimation(at: .start)
        } else {
            animator?.isReversed = true
            animator?.continueAnimation(withTimingParameters: timingCurve, durationFactor: completionSpeed)
        }
    }

    open override func responds(to aSelector: Selector!) -> Bool {
        let responds = super.responds(to: aSelector)
        if responds, aSelector == #selector(interruptibleAnimator(using:)) {
            return MainActor.assumeIsolated { isInterruptible }
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
        // This must be set before configuring, as view layout can sometimes trigger re-entry
        self.animator = animator
        configureTransitionAnimator(using: transitionContext, animator: animator)
        return animator
    }

    public func configureTransitionReaderCoordinator(
        presented: UIViewController,
        presentedView: UIView,
        presentedFrame: inout CGRect
    ) {
        guard isPresenting else { return }
        (presented as? AnyHostingController)?.render()

        guard
            let transitionReaderCoordinator = presented.transitionReaderCoordinator,
            let presentationController = presented.presentationController
        else {
            return
        }

        transitionReaderCoordinator.update(isPresented: true)

        if presentationController.presentedViewController.preferredContentSize != .zero {
            presentationController.presentedViewController.preferredContentSize = .zero
        }

        presentedView.setNeedsLayout()
        presentedView.layoutIfNeeded()

        presentedFrame = presentationController.frameOfPresentedViewInContainerView

        transitionReaderCoordinator.update(isPresented: false)
        presentedView.setNeedsLayout()
        presentedView.layoutIfNeeded()
    }

    open func configureTransitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
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

        let isPresenting = isPresenting
        if isPresenting {
            presentedView.alpha = 0
            var presentedFrame = transitionContext.finalFrame(for: presented)
            if presentedView.superview == nil {
                transitionContext.containerView.addSubview(presentedView)
            }
            presentedView.frame = presentedFrame
            presentedView.layoutIfNeeded()
            presentedFrame = presentedView.frame

            configureTransitionReaderCoordinator(
                presented: presented,
                presentedView: presentedView,
                presentedFrame: &presentedFrame
            )
        } else {
            if presentingView.superview == nil {
                transitionContext.containerView.insertSubview(presentingView, at: 0)
                presentingView.frame = transitionContext.finalFrame(for: presenting)
                presentingView.layoutIfNeeded()
            }
            presentedView.layoutIfNeeded()
        }
        animator.addAnimations {
            presentedView.alpha = isPresenting ? 1 : 0
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
