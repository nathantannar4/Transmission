//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension DestinationLinkTransition {

    /// The slide transition style.
    public static var slide: DestinationLinkTransition {
        .slide(.init())
    }

    /// The slide transition style.
    public static func slide(
        _ transitionOptions: SlideDestinationLinkTransition.Options,
        options: DestinationLinkTransition.Options = .init()
    ) -> DestinationLinkTransition {
        .custom(
            options: options,
            SlideDestinationLinkTransition(options: transitionOptions)
        )
    }

    /// The slide transition style.
    public static func slide(
        initialOpacity: CGFloat = 1,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> DestinationLinkTransition {
        .slide(
            .init(
                initialOpacity: initialOpacity
            ),
            options: .init(
                isInteractive: isInteractive,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
            )
        )
    }
}

@available(iOS 14.0, *)
public struct SlideDestinationLinkTransition: DestinationLinkTransitionRepresentable {

    /// The transition options for a slide transition.
    @frozen
    public struct Options {

        public var initialOpacity: CGFloat

        public init(
            initialOpacity: CGFloat = 1
        ) {
            self.initialOpacity = initialOpacity
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
    ) -> SlideNavigationControllerTransition? {
        let transition = SlideNavigationControllerTransition(
            initialOpacity: options.initialOpacity,
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
    ) -> SlideNavigationControllerTransition? {
        let transition = SlideNavigationControllerTransition(
            initialOpacity: options.initialOpacity,
            isPresenting: false,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = true
        return transition
    }
}

@available(iOS 14.0, *)
open class SlideNavigationControllerTransition: ViewControllerTransition {

    public let initialOpacity: CGFloat

    public init(
        initialOpacity: CGFloat,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.initialOpacity = initialOpacity
        super.init(isPresenting: isPresenting, animation: animation)
    }

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
        transitionContext.containerView.addSubview(toVC.view)
        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        toVC.view.transform = CGAffineTransform(
            translationX: isPresenting ? width : -width,
            y: 0
        )
        toVC.view.layoutIfNeeded()
        toVC.view.alpha = initialOpacity

        let fromVCTransform = CGAffineTransform(
            translationX: isPresenting ? -width : width,
            y: 0
        )

        animator.addAnimations { [initialOpacity] in
            toVC.view.transform = .identity
            toVC.view.alpha = 1
            fromVC.view.transform = fromVCTransform
            fromVC.view.alpha = initialOpacity
        }
        animator.addCompletion { animatingPosition in
            toVC.view.transform = .identity
            fromVC.view.transform = .identity
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
