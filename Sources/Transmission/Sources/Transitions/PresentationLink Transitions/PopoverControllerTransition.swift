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
        let sourceView = presentationController?.sourceView
        let sourceFrame = sourceView?.convert(sourceView?.bounds ?? .zero, to: transitionContext.containerView)

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
                sourceFrame: sourceFrame,
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

            let transform = transform(
                arrowDirection: presentationController?.arrowDirection ?? .unknown,
                sourceFrame: sourceFrame,
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

    func transform(
        arrowDirection: UIPopoverArrowDirection,
        sourceFrame: CGRect?,
        frame: CGRect
    ) -> CGAffineTransform {
        guard arrowDirection != .unknown, let sourceFrame else { return .identity }

        let anchor: UnitPoint = {
            switch arrowDirection {
            case .up:
                return .top
            case .down:
                return .bottom
            case .left:
                return .trailing
            case .right:
                return .leading
            default:
                return .center
            }
        }()

        let scale: CGFloat = 0.25
        let dx = sourceFrame.midX - frame.midX
        let dy = sourceFrame.midY - frame.midY
        let scaleTx = (anchor.x * dx) * (1 - scale)
        let scaleTy = (anchor.y * dy) * (1 - scale)



        return CGAffineTransform.identity
            .translatedBy(
                x: dx * (1 - anchor.x) / 2 + (dx * scale * (1 - anchor.x)),
                y: dy * (1 - anchor.y) / 2 + (dy * scale * (1 - anchor.y))
            )
            .translatedBy(
                x: scaleTx,
                y: scaleTy
            )
            .scaledBy(x: scale, y: scale)
    }
}

#endif
