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
            let presenting = transitionContext.viewController(forKey: isPresenting ? .from : .to),
            let presentedView = transitionContext.view(forKey: isPresenting ? .to : .from) ?? presented.view,
            let presentingView = transitionContext.view(forKey: isPresenting ? .from : .to) ?? presenting.view
        else {
            transitionContext.completeTransition(false)
            return
        }

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

            let dy = transitionContext.containerView.frame.height - presentedFrame.origin.y
            let transform = CGAffineTransform(
                translationX: 0,
                y: dy
            )
            presentedView.transform = transform
            presentedView.alpha = 1
            animator.addAnimations {
                presentedView.transform = .identity
            }
        } else {
            if presentingView.superview == nil {
                transitionContext.containerView.insertSubview(presentingView, at: 0)
                presentingView.frame = transitionContext.finalFrame(for: presenting)
                presentingView.layoutIfNeeded()
            }
            let frame = transitionContext.finalFrame(for: presented)
            let dy = transitionContext.containerView.frame.height - frame.origin.y
            let transform = CGAffineTransform(
                translationX: 0,
                y: dy
            )
            presentedView.layoutIfNeeded()

            animator.addAnimations {
                presentedView.transform = transform
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
    }
}

#endif
