//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
class ToastPresentationController: InteractivePresentationController {

    var edge: Edge {
        didSet {
            guard edge != oldValue else { return }
            switch edge {
            case .top, .leading:
                edges = .top
            case .bottom, .trailing:
                edges = .bottom
            }
            containerView?.setNeedsLayout()
        }
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard 
            let containerView = containerView,
            let presentedView = presentedView
        else { 
            return .zero
        }

        let inset: CGFloat = 16

        // Make sure to account for the safe area insets
        let safeAreaFrame = containerView.bounds
            .inset(by: containerView.safeAreaInsets)

        let targetWidth = safeAreaFrame.width - 2 * inset
        let fittingSize = CGSize(
            width: targetWidth,
            height: UIView.layoutFittingCompressedSize.height
        )
        let sizeThatFits = presentedView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        )

        var frame = safeAreaFrame
        frame.origin.x = (containerView.bounds.width - sizeThatFits.width) / 2
        switch edge {
        case .top, .leading:
            frame.origin.y = max(frame.origin.y, inset)
        case .bottom, .trailing:
            frame.origin.y += frame.size.height - sizeThatFits.height - inset
            frame.origin.y = min(frame.origin.y, containerView.frame.height - inset)
        }
        frame.size = sizeThatFits
        return frame
    }

    init(
        edge: Edge,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.edge = edge
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
        edges = Edge.Set(edge)
    }

    override func presentedViewAdditionalSafeAreaInsets() -> UIEdgeInsets {
        .zero
    }
}

@available(iOS 14.0, *)
class ToastTransition: PresentationControllerTransition {

    let edge: Edge

    init(
        isPresenting: Bool,
        animation: Animation?,
        edge: Edge
    ) {
        self.edge = edge
        super.init(isPresenting: isPresenting, animation: animation)
    }

    open override func transitionAnimator(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewPropertyAnimator {

        let animator = UIViewPropertyAnimator(animation: animation) ?? UIViewPropertyAnimator(duration: duration, curve: completionCurve)
        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from)
        else {
            transitionContext.completeTransition(false)
            return animator
        }

        if isPresenting {
            let frame = transitionContext.finalFrame(for: presented)
            transitionContext.containerView.addSubview(presented.view)
            presented.view.frame = frame
            switch edge {
            case .top, .leading:
                let transform = CGAffineTransform(
                    translationX: 0,
                    y: -presented.view.intrinsicContentSize.height - transitionContext.containerView.safeAreaInsets.top
                )
                presented.view.transform = transform
            case .bottom, .trailing:
                let transform = CGAffineTransform(
                    translationX: 0,
                    y: frame.size.height + transitionContext.containerView.safeAreaInsets.bottom
                )
                presented.view.transform = transform
            }
            animator.addAnimations {
                presented.view.transform = .identity
            }
        } else {
            let transform: CGAffineTransform
            switch edge {
            case .top, .leading:
                transform = CGAffineTransform(
                    translationX: 0,
                    y: -presented.view.intrinsicContentSize.height - transitionContext.containerView.safeAreaInsets.top
                )
            case .bottom, .trailing:
                let frame = transitionContext.finalFrame(for: presented)
                let dy = transitionContext.containerView.frame.height - frame.origin.y
                transform = CGAffineTransform(
                    translationX: 0,
                    y: dy
                )
            }
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
