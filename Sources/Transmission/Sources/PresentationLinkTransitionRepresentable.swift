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
public protocol PresentationLinkTransitionRepresentable:
    PresentationLinkPresentedTransitionRepresentable,
    PresentationLinkPresentingTransitionRepresentable,
    PresentationLinkDismissingTransitionRepresentable
{

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
@MainActor @preconcurrency
public protocol PresentationLinkPresentedTransitionRepresentable {

    typealias Context = PresentationLinkTransitionRepresentableContext
    associatedtype UIPresentationControllerType: UIPresentationController

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
}

@available(iOS 14.0, *)
extension PresentationLinkPresentedTransitionRepresentable {

    public func updateHostingController<Content: View>(
        presenting: PresentationHostingController<Content>,
        context: Context
    ) { }
}

@frozen
@available(iOS 14.0, *)
public struct PresentationLinkDefaultPresentedTransition: PresentationLinkPresentedTransitionRepresentable {

    public func makeUIPresentationController(
        presented: UIViewController,
        presenting: UIViewController?,
        context: Context
    ) -> InteractivePresentationController {
        let presentationController = InteractivePresentationController(
            presentedViewController: presented,
            presenting: presented
        )
        presentationController.presentedViewShadow = .minimal
        presentationController.dimmingView.isHidden = false
        return presentationController
    }

    public func updateUIPresentationController(
        presentationController: InteractivePresentationController,
        context: Context
    ) {

    }
}

@available(iOS 14.0, *)
extension PresentationLinkPresentedTransitionRepresentable where Self == PresentationLinkDefaultPresentedTransition {
    public static var `default`: PresentationLinkDefaultPresentedTransition { .init() }
}


@available(iOS 14.0, *)
@MainActor @preconcurrency
public protocol PresentationLinkPresentingTransitionRepresentable {

    typealias Context = PresentationLinkTransitionRepresentableContext
    associatedtype UIPresentingAnimationControllerType: UIViewControllerAnimatedTransitioning
    associatedtype UIPresentingInteractionControllerType: UIViewControllerInteractiveTransitioning

    /// The animation controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        context: Context
    ) -> UIPresentingAnimationControllerType?

    /// The interaction controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIPresentingInteractionControllerType?
}

@available(iOS 14.0, *)
extension PresentationLinkPresentingTransitionRepresentable {

    public func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}

@frozen
@available(iOS 14.0, *)
public struct PresentationLinkDefaultPresentingTransition: PresentationLinkPresentingTransitionRepresentable {

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        context: Context
    ) -> PresentationControllerTransition? {
        let transition = PresentationControllerTransition(
            isPresenting: true,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = false
        return transition
    }

    public func interactionControllerForPresentation(
        using animator: any UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> PresentationControllerTransition? {
        nil
    }
}

@available(iOS 14.0, *)
extension PresentationLinkPresentingTransitionRepresentable where Self == PresentationLinkDefaultPresentingTransition {
    public static var `default`: PresentationLinkDefaultPresentingTransition { .init() }
}

@available(iOS 14.0, *)
@MainActor @preconcurrency
public protocol PresentationLinkDismissingTransitionRepresentable {

    typealias Context = PresentationLinkTransitionRepresentableContext
    associatedtype UIDismissingAnimationControllerType: UIViewControllerAnimatedTransitioning
    associatedtype UIDismissingInteractionControllerType: UIViewControllerInteractiveTransitioning

    /// The animation controller to use for the transition dismissal.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func animationController(
        forDismissed dismissed: UIViewController,
        context: Context
    ) -> UIDismissingAnimationControllerType?

    /// The interaction controller to use for the transition dismissal.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIDismissingInteractionControllerType?
}

@available(iOS 14.0, *)
extension PresentationLinkDismissingTransitionRepresentable {

    public func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIViewControllerInteractiveTransitioning? {
        return animator as? UIViewControllerInteractiveTransitioning
    }
}

@frozen
@available(iOS 14.0, *)
public struct PresentationLinkDefaultDismissingTransition: PresentationLinkDismissingTransitionRepresentable {

    public func animationController(
        forDismissed dismissed: UIViewController,
        context: Context
    ) -> PresentationControllerTransition? {
        guard let presentationController = dismissed.presentationController as? InteractivePresentationController else {
            return nil
        }
        let animation: Animation? = {
            guard context.transaction.animation == .default else {
                return context.transaction.animation
            }
            return presentationController.preferredDefaultAnimation() ?? context.transaction.animation
        }()
        let transition = PresentationControllerTransition(
            isPresenting: false,
            animation: animation
        )
        transition.wantsInteractiveStart = presentationController.wantsInteractiveTransition
        presentationController.transition(with: transition)
        return transition
    }
}

@available(iOS 14.0, *)
extension PresentationLinkDismissingTransitionRepresentable where Self == PresentationLinkDefaultDismissingTransition {
    public static var `default`: PresentationLinkDefaultDismissingTransition { .init() }
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
