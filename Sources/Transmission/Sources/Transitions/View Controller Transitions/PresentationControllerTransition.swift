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
            var presentedFrame = transitionContext.finalFrame(for: presented)
            if presentedView.superview == nil {
                transitionContext.containerView.addSubview(presentedView)
            }
            presentedView.frame = presentedFrame
            presentedView.layoutIfNeeded()

            (presented as? AnyHostingController)?.render()

            if let transitionReaderCoordinator = presented.transitionReaderCoordinator {
                transitionReaderCoordinator.update(isPresented: true)

                presentedView.setNeedsLayout()
                presentedView.layoutIfNeeded()

                if let presentationController = presented.presentationController as? PresentationController {
                    presentedFrame = presentationController.frameOfPresentedViewInContainerView
                }

                transitionReaderCoordinator.update(isPresented: false)
                presentedView.setNeedsLayout()
                presentedView.layoutIfNeeded()
                transitionReaderCoordinator.update(isPresented: true)
            }

            let transform = CGAffineTransform(
                translationX: 0,
                y: presentedFrame.size.height + transitionContext.containerView.safeAreaInsets.bottom
            )
            presentedView.transform = transform
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
