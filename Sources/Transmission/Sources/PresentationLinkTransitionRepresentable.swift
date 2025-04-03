//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import EngineCore

/// The context for a ``PresentationLinkTransitionRepresentable``
@available(iOS 14.0, *)
public struct PresentationLinkTransitionRepresentableContext {
    public var sourceView: UIView
    public var options: PresentationLinkTransition.Options
    public var environment: EnvironmentValues
    public var transaction: Transaction
}

/// A protocol that defines a custom transition for a ``PresentationLinkTransition``
///
/// > Important: Conforming types should be a struct or an enum
/// > Tip: Use ``PresentationController`` or ``InteractivePresentationController``
///
@available(iOS 14.0, *)
@MainActor @preconcurrency
public protocol PresentationLinkTransitionRepresentable {

    typealias Context = PresentationLinkTransitionRepresentableContext
    associatedtype UIPresentationControllerType: UIPresentationController
    associatedtype UIAnimationControllerType: UIViewControllerAnimatedTransitioning
    associatedtype UIInteractionControllerType: UIViewControllerInteractiveTransitioning

    /// The presentation controller to use for the transition.
    @MainActor @preconcurrency func makeUIPresentationController(
        presented: UIViewController,
        presenting: UIViewController?,
        context: Context
    ) -> UIPresentationControllerType

    /// Updates the presentation controller for the transition
    @MainActor @preconcurrency func updateUIPresentationController(
        presentationController: UIPresentationControllerType,
        context: Context
    )

    /// Updates the presented hosting controller
    @MainActor @preconcurrency func updateHostingController<Content: View>(
        presenting: PresentationHostingController<Content>,
        context: Context
    )

    /// The animation controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        context: Context
    ) -> UIAnimationControllerType?

    /// The animation controller to use for the transition dismissal.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func animationController(
        forDismissed dismissed: UIViewController,
        context: Context
    ) -> UIAnimationControllerType?

    /// The interaction controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIInteractionControllerType?

    /// The interaction controller to use for the transition dismissal.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIInteractionControllerType?

    /// The presentation style to use for an adaptive presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `.none`
    ///
    @MainActor @preconcurrency func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle

    /// The presentation controller to use for an adaptive presentation.
    ///
    /// > Note: This protocol implementation is optional
    ///
    @MainActor @preconcurrency func updateAdaptivePresentationController(
        adaptivePresentationController: UIPresentationController,
        context: Context
    )
}

@available(iOS 14.0, *)
extension PresentationLinkTransitionRepresentable {

    public func updateHostingController<Content: View>(
        presenting: PresentationHostingController<Content>,
        context: Context
    ) {

    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        context: Context
    ) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }

    public func animationController(
        forDismissed dismissed: UIViewController,
        context: Context
    ) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }

    public func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    public func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    public func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        return .none
    }

    public func updateAdaptivePresentationController(
        adaptivePresentationController: UIPresentationController,
        context: Context
    ) {
        
    }
}

@available(iOS 14.0, *)
extension PresentationLinkTransitionRepresentable
    where UIPresentationControllerType: InteractivePresentationController
{
    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        context: Context
    ) -> UIViewControllerAnimatedTransitioning? {
        let transition = PresentationControllerTransition(
            isPresenting: true,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = false
        return transition
    }

    public func animationController(
        forDismissed dismissed: UIViewController,
        context: Context
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let presentationController = dismissed.presentationController as? UIPresentationControllerType else {
            return nil
        }
        let transition = PresentationControllerTransition(
            isPresenting: false,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = presentationController.wantsInteractiveTransition
        presentationController.transition(with: transition)
        return transition
    }

    public func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIViewControllerInteractiveTransitioning? {
        return animator as? PresentationControllerTransition
    }
}

#endif
