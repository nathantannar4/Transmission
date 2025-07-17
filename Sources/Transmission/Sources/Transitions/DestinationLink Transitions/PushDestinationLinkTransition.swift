//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension DestinationLinkTransition {

    /// The push transition style.
    public static var push: DestinationLinkTransition {
        .push(.init())
    }

    /// The push transition style.
    public static func push(
        _ transitionOptions: PushDestinationLinkTransition.Options,
        options: DestinationLinkTransition.Options = .init(
            prefersPanGesturePop: true
        )
    ) -> DestinationLinkTransition {
        .custom(
            options: options,
            PushDestinationLinkTransition(options: transitionOptions)
        )
    }

    /// The push transition style.
    public static func push(
        prefersPanGesturePop: Bool = true,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> DestinationLinkTransition {
        .push(
            .init(
            ),
            options: .init(
                isInteractive: isInteractive,
                prefersPanGesturePop: prefersPanGesturePop,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor,
            )
        )
    }
}

@available(iOS 14.0, *)
public struct PushDestinationLinkTransition: DestinationLinkTransitionRepresentable {

    /// The transition options for a push transition.
    @frozen
    public struct Options {

        public init() {
        }
    }
    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        pushing toVC: UIViewController,
        from fromVC: UIViewController,
        context: Context
    ) -> PushNavigationControllerTransition? {
        let transition = PushNavigationControllerTransition(
            isPresenting: true,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = false
        return transition
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        popping fromVC: UIViewController,
        to toVC: UIViewController,
        context: Context
    ) -> PushNavigationControllerTransition? {
        let transition = PushNavigationControllerTransition(
            isPresenting: false,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = true
        return transition
    }
}

@available(iOS 14.0, *)
open class PushNavigationControllerTransition: ViewControllerTransition {

    open override func configureTransitionAnimator(
        using transitionContext: any UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }


        let width = transitionContext.containerView.frame.width
        let offset = width * 0.3
        let isPresenting = isPresenting
        if isPresenting {
            transitionContext.containerView.addSubview(toVC.view)
        } else {
            transitionContext.containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        }

        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        toVC.view.layoutIfNeeded()

        let dimmingView = UIView()
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.12)
        dimmingView.alpha = isPresenting ? 0 : 1
        dimmingView.isUserInteractionEnabled = false
        transitionContext.containerView.insertSubview(
            dimmingView,
            aboveSubview: isPresenting ? fromVC.view : toVC.view
        )
        dimmingView.frame = isPresenting ? fromVC.view.frame : toVC.view.frame

        let toVCTransform = CGAffineTransform(
            translationX: isPresenting ? width : -offset,
            y: 0
        )
        toVC.view.transform = toVCTransform
        if !isPresenting {
            dimmingView.transform = toVCTransform
        }
        let fromVCTransform = CGAffineTransform(
            translationX: isPresenting ? -offset : width,
            y: 0
        )

        animator.addAnimations {
            toVC.view.transform = .identity
            fromVC.view.transform = fromVCTransform
            dimmingView.alpha = isPresenting ? 1 : 0
            dimmingView.transform = isPresenting ? fromVCTransform : .identity
        }
        animator.addCompletion { animatingPosition in
            toVC.view.transform = .identity
            fromVC.view.transform = .identity
            dimmingView.removeFromSuperview()
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
