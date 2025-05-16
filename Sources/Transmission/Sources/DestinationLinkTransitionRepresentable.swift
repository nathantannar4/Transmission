//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import EngineCore

/// The context for a ``DestinationLinkTransitionRepresentableContext``
@available(iOS 14.0, *)
@frozen
public struct DestinationLinkTransitionRepresentableContext {
    public weak var sourceView: UIView?
    public var options: DestinationLinkTransition.Options
    public var environment: EnvironmentValues
    public var transaction: Transaction
}

/// A protocol that defines a custom transition for a ``DestinationLinkTransition``
@available(iOS 14.0, *)
@MainActor @preconcurrency
public protocol DestinationLinkTransitionRepresentable {

    typealias Context = DestinationLinkTransitionRepresentableContext

    /// The interaction controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIViewControllerInteractiveTransitioning?

    /// The animation controller to use for the transition presentation.
    @MainActor @preconcurrency func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController,
        context: Context
    ) -> UIViewControllerAnimatedTransitioning?
}

@available(iOS 14.0, *)
extension DestinationLinkTransitionRepresentable {

    public func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}

#endif
