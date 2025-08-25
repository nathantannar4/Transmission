//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
open class PresentationControllerTransition: ViewControllerTransition {

    public override init(
        isPresenting: Bool,
        animation: Animation?
    ) {
        super.init(isPresenting: isPresenting, animation: animation)
        wantsInteractiveStart = true
    }

    open override func animatedStarted(
        transitionContext: UIViewControllerContextTransitioning
    ) {
        if let presentationController = transitionContext.presentationController(isPresenting: isPresenting) as? PresentationController {
            presentationController.layoutBackgroundViews()
        }
    }

    open override func configureTransitionAnimator(
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

        if isPresenting {
            let presentedFrame = transitionContext.finalFrame(for: presented)
            transitionContext.containerView.addSubview(presented.view)
            presented.view.frame = presentedFrame
            presented.view.layoutIfNeeded()

            let transform = CGAffineTransform(
                translationX: 0,
                y: presentedFrame.size.height + transitionContext.containerView.safeAreaInsets.bottom
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
            presented.view.layoutIfNeeded()

            animator.addAnimations {
                presented.view.transform = transform
            }
        }
        animator.addCompletion { animatingPosition in
            Task { @MainActor in
                switch animatingPosition {
                case .end:
                    transitionContext.completeTransition(true)
                default:
                    transitionContext.completeTransition(false)
                }
            }
        }
    }
}

#endif
