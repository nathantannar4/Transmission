//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    public static func asymmetric<
        PresentedController: PresentationLinkPresentedTransitionRepresentable,
        PresentingAnimationController: PresentationLinkPresentingTransitionRepresentable,
        DismissingAnimationController: PresentationLinkDismissingTransitionRepresentable
    >(
        presented presentedController: PresentedController,
        presenting presentingAnimationController: PresentingAnimationController,
        dismissing dismissingAnimationController: DismissingAnimationController,
        options: PresentationLinkTransition.Options = .init(
            modalPresentationCapturesStatusBarAppearance: true
        )
    ) -> PresentationLinkTransition {
        .custom(
            options: options,
            PresentationLinkAsymmetricTransition(
                presented: presentedController,
                presenting: presentingAnimationController,
                dismissing: dismissingAnimationController
            )
        )
    }
}

@frozen
@available(iOS 14.0, *)
public struct PresentationLinkAsymmetricTransition<
    PresentedController: PresentationLinkPresentedTransitionRepresentable,
    PresentingAnimationController: PresentationLinkPresentingTransitionRepresentable,
    DismissingAnimationController: PresentationLinkDismissingTransitionRepresentable
>: PresentationLinkTransitionRepresentable {

    public typealias UIPresentationControllerType = PresentedController.UIPresentationControllerType
    public typealias UIPresentingAnimationControllerType = PresentingAnimationController.UIPresentingAnimationControllerType
    public typealias UIPresentingInteractionControllerType = PresentingAnimationController.UIPresentingInteractionControllerType
    public typealias UIDismissingAnimationControllerType = DismissingAnimationController.UIDismissingAnimationControllerType
    public typealias UIDismissingInteractionControllerType = DismissingAnimationController.UIDismissingInteractionControllerType

    public var presentedController: PresentedController
    public var presentingAnimationController: PresentingAnimationController
    public var dismissingAnimationController: DismissingAnimationController

    public init(
        presented presentedController: PresentedController,
        presenting presentingAnimationController: PresentingAnimationController,
        dismissing dismissingAnimationController: DismissingAnimationController
    ) {
        self.presentedController = presentedController
        self.presentingAnimationController = presentingAnimationController
        self.dismissingAnimationController = dismissingAnimationController
    }

    public func makeUIPresentationController(
        presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController,
        context: Context
    ) -> UIPresentationControllerType {
        let presentationController = presentedController.makeUIPresentationController(
            presented: presented,
            presenting: presenting,
            source: source,
            context: context
        )
        if DismissingAnimationController.self != PresentedController.self,
           let interactivePresentationController = presentationController as? InteractivePresentationController
        {
            interactivePresentationController.prefersInteractiveDismissal = true
        }
        return presentationController
    }

    public func updateUIPresentationController(
        presentationController: UIPresentationControllerType,
        context: Context
    ) {
        presentedController.updateUIPresentationController(
            presentationController: presentationController,
            context: context
        )
    }

    public func updateHostingController<Content: View>(
        presenting: PresentationHostingController<Content>,
        context: Context
    ) {
        presentedController.updateHostingController(
            presenting: presenting,
            context: context
        )
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        presentationController: UIPresentationController,
        context: Context
    ) -> UIPresentingAnimationControllerType? {
        presentingAnimationController.animationController(
            forPresented: presented,
            presenting: presenting,
            presentationController: presentationController,
            context: context
        )
    }

    public func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIPresentingInteractionControllerType? {
        presentingAnimationController.interactionControllerForPresentation(
            using: animator,
            context: context
        )
    }

    public func animationController(
        forDismissed dismissed: UIViewController,
        presentationController: UIPresentationController,
        context: Context
    ) -> UIDismissingAnimationControllerType? {
        let animationController = dismissingAnimationController.animationController(
            forDismissed: dismissed,
            presentationController: presentationController,
            context: context
        )
        if UIPresentingAnimationControllerType.self == MatchedGeometryPresentationControllerTransition.self,
           UIDismissingAnimationControllerType.self != MatchedGeometryPresentationControllerTransition.self
        {
            context.sourceView?.alpha = 1
        }
        return animationController
    }

    public func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIDismissingInteractionControllerType? {
        dismissingAnimationController.interactionControllerForDismissal(
            using: animator,
            context: context
        )
    }
}

#endif
