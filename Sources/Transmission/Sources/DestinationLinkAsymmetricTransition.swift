//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

@available(iOS 14.0, *)
extension DestinationLinkTransition {

    public static func asymmetric<
        PushAnimationController: DestinationLinkPushTransitionRepresentable,
        PopAnimationController: DestinationLinkPopTransitionRepresentable
    >(
        push pushAnimationController: PushAnimationController,
        pop popAnimationController: PopAnimationController,
        options: DestinationLinkTransition.Options = .init()
    ) -> DestinationLinkTransition {
        .custom(
            options: options,
            DestinationLinkTransitionAsymmetricTransition(
                push: pushAnimationController,
                pop: popAnimationController
            )
        )
    }
}

@frozen
@available(iOS 14.0, *)
public struct DestinationLinkTransitionAsymmetricTransition<
    PushAnimationController: DestinationLinkPushTransitionRepresentable,
    PopAnimationController: DestinationLinkPopTransitionRepresentable
>: DestinationLinkTransitionRepresentable {

    public typealias UIPushAnimationControllerType = PushAnimationController.UIPushAnimationControllerType
    public typealias UIPushInteractionControllerType = PushAnimationController.UIPushInteractionControllerType
    public typealias UIPopAnimationControllerType = PopAnimationController.UIPopAnimationControllerType
    public typealias UIPopInteractionControllerType = PopAnimationController.UIPopInteractionControllerType

    public var pushAnimationController: PushAnimationController
    public var popAnimationController: PopAnimationController

    public init(
        push pushAnimationController: PushAnimationController,
        pop popAnimationController: PopAnimationController
    ) {
        self.pushAnimationController = pushAnimationController
        self.popAnimationController = popAnimationController
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        pushing toVC: UIViewController,
        from fromVC: UIViewController,
        context: Context
    ) -> UIPushAnimationControllerType? {
        pushAnimationController.navigationController(
            navigationController,
            pushing: toVC,
            from: fromVC,
            context: context
        )
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerForPush animationController: any UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIPushInteractionControllerType? {
        pushAnimationController.navigationController(
            navigationController,
            interactionControllerForPush: animationController,
            context: context
        )
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        popping fromVC: UIViewController,
        to toVC: UIViewController,
        context: Context
    ) -> UIPopAnimationControllerType? {
        if UIPushAnimationControllerType.self == MatchedGeometryPresentationControllerTransition.self,
           UIPopAnimationControllerType.self != MatchedGeometryPresentationControllerTransition.self
        {
            context.sourceView?.alpha = 1
        }
        return popAnimationController.navigationController(
            navigationController,
            popping: fromVC,
            to: toVC,
            context: context
        )
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerForPop animationController: any UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIPopInteractionControllerType? {
        popAnimationController.navigationController(
            navigationController,
            interactionControllerForPop: animationController,
            context: context
        )
    }
}

#endif
