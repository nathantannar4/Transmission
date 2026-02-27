//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    /// The cross dissolve presentation style.
    public static let crossDissolve: PresentationLinkTransition = .crossDissolve()

    /// The cross dissolve presentation style.
    public static func crossDissolve(
        _ transitionOptions: CrossDissolvePresentationLinkTransition.Options,
        options: PresentationLinkTransition.Options = .init(
            modalPresentationCapturesStatusBarAppearance: true
        )
    ) -> PresentationLinkTransition {
        .custom(
            options: options,
            CrossDissolvePresentationLinkTransition(options: transitionOptions)
        )
    }

    /// The cross dissolve transition style.
    public static func crossDissolve(
        transform: CGAffineTransform = .identity,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .crossDissolve(
            .init(
                transform: transform
            ),
            options: .init(
                isInteractive: isInteractive,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
            )
        )
    }
}

@frozen
@available(iOS 14.0, *)
public struct CrossDissolvePresentationLinkTransition: PresentationLinkTransitionRepresentable {

    /// The transition options for a cross dissolve transition.
    @frozen
    public struct Options: Sendable {

        public var transform: CGAffineTransform

        public init(
            transform: CGAffineTransform = .identity
        ) {
            self.transform = transform
        }
    }

    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }

    public func makeUIPresentationController(
        presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController,
        context: Context
    ) -> InteractivePresentationController {
        let presentationController = InteractivePresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
        return presentationController
    }

    public func updateUIPresentationController(
        presentationController: InteractivePresentationController,
        context: Context
    ) {
        var edges: Edge.Set = []
        if options.transform.ty > 0 {
            edges.formUnion(.bottom)
        }
        if options.transform.ty < 0 {
            edges.formUnion(.top)
        }
        if options.transform.tx < 0 {
            edges.formUnion(.leading)
        }
        if options.transform.tx > 0 {
            edges.formUnion(.trailing)
        }
        presentationController.edges = edges
        presentationController.isInteractive = context.options.isInteractive
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        presentationController: UIPresentationController,
        context: Context
    ) -> CrossDissolveControllerTransition? {
        let transition = CrossDissolveControllerTransition(
            transform: options.transform,
            isPresenting: true,
            animation: context.transaction.animation
        )
        if let presentationController = presentationController as? PresentationController {
            presentationController.attach(to: transition)
        } else {
            transition.wantsInteractiveStart = false
        }
        return transition
    }

    public func animationController(
        forDismissed dismissed: UIViewController,
        presentationController: UIPresentationController,
        context: Context
    ) -> CrossDissolveControllerTransition? {
        let transition = CrossDissolveControllerTransition(
            transform: options.transform,
            isPresenting: false,
            animation: context.transaction.animation
        )
        if let presentationController = presentationController as? PresentationController {
            presentationController.attach(to: transition)
        } else {
            transition.wantsInteractiveStart = false
        }
        return transition
    }
}

@available(iOS 14.0, *)
open class CrossDissolveControllerTransition: PresentationControllerTransition {

    public let transform: CGAffineTransform

    public init(
        transform: CGAffineTransform,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.transform = transform
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

        if isPresenting {
            presentedView.alpha = 0
            var presentedFrame = transitionContext.finalFrame(for: presented)
            if presentedView.superview == nil {
                transitionContext.containerView.addSubview(presentedView)
            }
            presentedView.frame = presentedFrame
            presentedView.layoutIfNeeded()

            configureTransitionReaderCoordinator(
                presented: presented,
                presentedView: presentedView,
                presentedFrame: &presentedFrame
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

            let transform = transform
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
}

#endif
