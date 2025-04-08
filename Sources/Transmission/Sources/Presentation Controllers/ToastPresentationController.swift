//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    /// The toast presentation style.
    public static let toast: PresentationLinkTransition = .toast()

    /// The toast presentation style.
    public static func toast(
        _ transitionOptions: ToastPresentationLinkTransition.Options,
        options: PresentationLinkTransition.Options = .init()
    ) -> PresentationLinkTransition {
        .custom(
            options: options,
            ToastPresentationLinkTransition(options: transitionOptions)
        )
    }

    /// The toast presentation style.
    public static func toast(
        edge: Edge = .bottom,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = .clear
    ) -> PresentationLinkTransition {
        .toast(
            .init(
                edge: edge,
                preferredPresentationShadow: preferredPresentationBackgroundColor == .clear ? .clear : .minimal
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
public struct ToastPresentationLinkTransition: PresentationLinkTransitionRepresentable {

    /// The transition options for a card transition.
    @frozen
    public struct Options {

        public var edge: Edge
        public var preferredPresentationShadow: PresentationLinkTransition.Shadow

        public init(
            edge: Edge = .bottom,
            preferredPresentationShadow: PresentationLinkTransition.Shadow = .minimal
        ) {
            self.edge = edge
            self.preferredPresentationShadow = preferredPresentationShadow
        }
    }
    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }

    public func makeUIPresentationController(
        presented: UIViewController,
        presenting: UIViewController?,
        context: Context
    ) -> ToastPresentationController {
        let presentationController = ToastPresentationController(
            edge: options.edge,
            presentedViewController: presented,
            presenting: presenting
        )
        presentationController.presentedViewShadow = options.preferredPresentationShadow
        return presentationController
    }

    public func updateUIPresentationController(
        presentationController: ToastPresentationController,
        context: Context
    ) {
        presentationController.edge = options.edge
        presentationController.presentedViewShadow = options.preferredPresentationShadow
    }

    public func updateHostingController<Content>(
        presenting: PresentationHostingController<Content>,
        context: Context
    ) where Content: View {
        presenting.tracksContentSize = true
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        context: Context
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        let transition = ToastPresentationControllerTransition(
            edge: options.edge,
            isPresenting: true,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = false
        return transition
    }

    public func animationController(
        forDismissed dismissed: UIViewController,
        context: Context
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        guard let presentationController = dismissed.presentationController as? InteractivePresentationController else {
            return nil
        }
        let transition = ToastPresentationControllerTransition(
            edge: options.edge,
            isPresenting: false,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = presentationController.wantsInteractiveTransition
        presentationController.transition(with: transition)
        return transition
    }
}

/// A presentation controller that presents the view in its ideal size at the top or bottom
@available(iOS 14.0, *)
open class ToastPresentationController: InteractivePresentationController {

    public var edge: Edge {
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

    open override var frameOfPresentedViewInContainerView: CGRect {
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
            height: UIView.layoutFittingExpandedSize.height
        )
        var sizeThatFits = presentedView.systemLayoutSizeFitting(fittingSize)
        if sizeThatFits.height <= 0 {
            sizeThatFits.height = targetWidth
        }
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

    public init(
        edge: Edge = .top,
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

    open override func presentedViewAdditionalSafeAreaInsets() -> UIEdgeInsets {
        .zero
    }
}

/// An interactive transition built for the ``ToastPresentationController``.
///
/// ```
/// func animationController(
///     forPresented presented: UIViewController,
///     presenting: UIViewController,
///     source: UIViewController
/// ) -> UIViewControllerAnimatedTransitioning? {
///     let transition = ToastPresentationControllerTransition(...)
///     transition.wantsInteractiveStart = false
///     return transition
/// }
///
/// func animationController(
///     forDismissed dismissed: UIViewController
/// ) -> UIViewControllerAnimatedTransitioning? {
///     guard let presentationController = dismissed.presentationController as? ToastPresentationController else {
///         return nil
///     }
///     let transition = ToastPresentationControllerTransition(...)
///     transition.wantsInteractiveStart = presentationController.wantsInteractiveTransition
///     presentationController.transition(with: transition)
///     return transition
/// }
///
/// func interactionControllerForDismissal(
///     using animator: UIViewControllerAnimatedTransitioning
/// ) -> UIViewControllerInteractiveTransitioning? {
///     return animator as? ToastPresentationControllerTransition
/// }
/// ```
///
@available(iOS 14.0, *)
open class ToastPresentationControllerTransition: PresentationControllerTransition {

    public let edge: Edge

    public init(
        edge: Edge,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.edge = edge
        super.init(isPresenting: isPresenting, animation: animation)
    }

    open override func configureTransitionAnimator(
        using transitionContext: any UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {

        guard
            let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from)
        else {
            transitionContext.completeTransition(false)
            return
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
    }
}

#endif
