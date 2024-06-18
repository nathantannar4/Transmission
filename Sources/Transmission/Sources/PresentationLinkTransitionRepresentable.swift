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
        context: Context,
        presented: UIViewController,
        presenting: UIViewController?
    ) -> UIPresentationControllerType

    /// Updates the presentation controller for the transition
    @MainActor @preconcurrency func updateUIPresentationController(
        presentationController: UIPresentationControllerType,
        context: Context
    )

    /// The animation controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController
    ) -> UIAnimationControllerType?

    /// The animation controller to use for the transition dismissal.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIAnimationControllerType?

    /// The interaction controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIInteractionControllerType?

    /// The interaction controller to use for the transition dismissal.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
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
    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }

    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }

    public func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    public func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
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
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let presentationController = dismissed.presentationController as? UIPresentationControllerType else {
            return nil
        }
        let transition = PresentationControllerTransition(
            isPresenting: false
        )
        transition.wantsInteractiveStart = presentationController.wantsInteractiveTransition
        presentationController.transition(with: transition)
        return transition
    }

    public func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return animator as? PresentationControllerTransition
    }
}

#endif
