//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

public struct SlideTransitionAnimator: ViewControllerTransitionAnimator {

    public var edge: Edge
    public var initialOpacity: CGFloat
    public var animatedViews: Set<UITransitionContextViewControllerKey>

    public init(
        edge: Edge,
        initialOpacity: CGFloat,
        animatedViews: Set<UITransitionContextViewControllerKey>
    ) {
        self.edge = edge
        self.initialOpacity = initialOpacity
        self.animatedViews = animatedViews
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

            if animatedViews.contains(.to) {
                let transform = transform(
                    frame: presentedFrame,
                    layoutDirection: transitionContext.containerView.effectiveUserInterfaceLayoutDirection
                )
                presentedView.transform = transform
                presentedView.alpha = initialOpacity
                animator.addAnimations {
                    presentedView.alpha = 1
                    presentedView.transform = .identity
                }
            } else {
                presentedView.alpha = 1
            }
            if animatedViews.contains(.from) {
                let transform = transform(
                    frame: transitionContext.initialFrame(for: presenting),
                    layoutDirection: transitionContext.containerView.effectiveUserInterfaceLayoutDirection
                )
                animator.addAnimations { [initialOpacity] in
                    presentingView.alpha = initialOpacity
                    presentingView.transform = transform.inverted()
                }
            }
        } else {
            if presentingView.superview == nil {
                transitionContext.containerView.insertSubview(presentingView, at: 0)
                presentingView.frame = transitionContext.finalFrame(for: presenting)
                presentingView.layoutIfNeeded()
            }
            presentedView.layoutIfNeeded()

            if animatedViews.contains(.to) {
                let frame = transitionContext.initialFrame(for: presented)
                let transform = transform(
                    frame: frame,
                    layoutDirection: transitionContext.containerView.effectiveUserInterfaceLayoutDirection
                )
                animator.addAnimations { [initialOpacity] in
                    presentedView.alpha = initialOpacity
                    presentedView.transform = transform
                }
            }
            if animatedViews.contains(.from) {
                let transform = transform(
                    frame: transitionContext.finalFrame(for: presenting),
                    layoutDirection: transitionContext.containerView.effectiveUserInterfaceLayoutDirection
                )
                presentingView.alpha = initialOpacity
                presentingView.transform = transform.inverted()
                animator.addAnimations {
                    presentingView.alpha = 1
                    presentingView.transform = .identity
                }
            }
        }
        animator.addCompletion { animatingPosition in
            presentedView.alpha = 1
            presentedView.transform = .identity
            presentingView.alpha = 1
            presentingView.transform = .identity
            switch animatingPosition {
            case .end:
                transitionContext.completeTransition(true)
            default:
                transitionContext.completeTransition(false)
            }
        }
    }

    private func transform(
        frame: CGRect,
        layoutDirection: UIUserInterfaceLayoutDirection
    ) -> CGAffineTransform {
        switch edge {
        case .top:
            return CGAffineTransform(translationX: 0, y: -frame.maxY)
        case .bottom:
            return CGAffineTransform(translationX: 0, y: frame.maxY)
        case .leading:
            switch layoutDirection {
            case .rightToLeft:
                return CGAffineTransform(translationX: frame.maxX, y: 0)
            default:
                return CGAffineTransform(translationX: -frame.maxX, y: 0)
            }
        case .trailing:
            switch layoutDirection {
            case .leftToRight:
                return CGAffineTransform(translationX: frame.maxX, y: 0)
            default:
                return CGAffineTransform(translationX: -frame.maxX, y: 0)
            }
        }
    }
}

#endif
