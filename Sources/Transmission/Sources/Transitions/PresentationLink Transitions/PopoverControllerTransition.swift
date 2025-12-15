//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
open class PopoverControllerTransition: PresentationControllerTransition {

    public override init(
        isPresenting: Bool,
        animation: Animation?
    ) {
        super.init(
            isPresenting: isPresenting,
            animation: animation
        )
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

        let presentationController = transitionContext.presentationController(isPresenting: isPresenting) as? UIPopoverPresentationController

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

            let transform = transform(
                arrowDirection: presentationController?.arrowDirection ?? .unknown,
                frame: presentedFrame
            )
            presentedView.transform = transform
            animator.addAnimations {
                presentedView.alpha = 1
                presentedView.transform = .identity
            }
        } else {
            if presentingView.superview == nil {
                transitionContext.containerView.insertSubview(presentingView, at: 0)
                presentingView.frame = transitionContext.finalFrame(for: presenting)
                presentingView.layoutIfNeeded()
            }
            presentedView.layoutIfNeeded()

            configureTransitionReaderCoordinator(
                presented: presented,
                presentedView: presentedView
            )

            let transform = transform(
                arrowDirection: presentationController?.arrowDirection ?? .unknown,
                frame: presentedView.frame
            )
            animator.addAnimations {
                presentedView.alpha = 0
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

    private func transform(
        arrowDirection: UIPopoverArrowDirection,
        frame: CGRect
    ) -> CGAffineTransform {
        guard arrowDirection != .unknown else { return .identity }

        let origin: CGPoint = {
            switch arrowDirection {
            case .up:
                return CGPoint(x: frame.width / 2, y: 0)
            case .down:
                return CGPoint(x: frame.width / 2, y: frame.height)
            case .left:
                return CGPoint(x: 0, y: frame.height / 2)
            case .right:
                return CGPoint(x: frame.width, y: frame.height / 2)
            default:
                return CGPoint(x: frame.width / 2, y: frame.height / 2)
            }
        }()

        let scale: CGFloat = 0.25
        let tx = (origin.x - frame.width / 2) * (1 - scale)
        let ty = (origin.y - frame.height / 2) * (1 - scale)

        return CGAffineTransform.identity
            .translatedBy(x: tx, y: ty)
            .scaledBy(x: scale, y: scale)
    }
}

#endif
