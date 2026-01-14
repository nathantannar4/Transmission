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
    public var sourceView: UIView?
    public var options: DestinationLinkTransition.Options
    public var environment: EnvironmentValues
    public var transaction: Transaction
}

/// A protocol that defines a custom transition for a ``DestinationLinkTransition``
@available(iOS 14.0, *)
@MainActor @preconcurrency
public protocol DestinationLinkTransitionRepresentable: DestinationLinkPushTransitionRepresentable, DestinationLinkPopTransitionRepresentable {

    /// Updates the presented hosting controller
    @MainActor @preconcurrency func updateHostingController<Content: View>(
        presenting: HostingController<Content>,
        context: Context
    )
}

@available(iOS 14.0, *)
extension DestinationLinkTransitionRepresentable {

    public func updateHostingController<Content: View>(
        presenting: HostingController<Content>,
        context: Context
    ) { }
}

/// A protocol that defines a custom push transition for a ``DestinationLinkTransition``
@available(iOS 14.0, *)
@MainActor @preconcurrency
public protocol DestinationLinkPushTransitionRepresentable: Sendable {

    typealias Context = DestinationLinkTransitionRepresentableContext
    associatedtype UIPushAnimationControllerType: UIViewControllerAnimatedTransitioning
    associatedtype UIPushInteractionControllerType: UIViewControllerInteractiveTransitioning

    /// The interaction controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerForPush animationController: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIPushInteractionControllerType?

    /// The animation controller to use for the transition presentation.
    @MainActor @preconcurrency func navigationController(
        _ navigationController: UINavigationController,
        pushing toVC: UIViewController,
        from fromVC: UIViewController,
        context: Context
    ) -> UIPushAnimationControllerType?
}

@available(iOS 14.0, *)
extension DestinationLinkPushTransitionRepresentable {

    public func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerForPush animationController: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}

@frozen
@available(iOS 14.0, *)
public struct DestinationLinkDefaultPushTransition: DestinationLinkPushTransitionRepresentable {

    public func navigationController(
        _ navigationController: UINavigationController,
        pushing toVC: UIViewController,
        from fromVC: UIViewController,
        context: Context
    ) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}

@available(iOS 14.0, *)
extension DestinationLinkPushTransitionRepresentable where Self == DestinationLinkDefaultPushTransition {
    public static var `default`: DestinationLinkDefaultPushTransition { .init() }
}

/// A protocol that defines a custom pop transition for a ``DestinationLinkTransition``
@available(iOS 14.0, *)
@MainActor @preconcurrency
public protocol DestinationLinkPopTransitionRepresentable: Sendable {

    typealias Context = DestinationLinkTransitionRepresentableContext
    associatedtype UIPopAnimationControllerType: UIViewControllerAnimatedTransitioning
    associatedtype UIPopInteractionControllerType: UIViewControllerInteractiveTransitioning

    /// The interaction controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerForPop animationController: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIPopInteractionControllerType?

    /// The animation controller to use for the transition presentation.
    @MainActor @preconcurrency func navigationController(
        _ navigationController: UINavigationController,
        popping fromVC: UIViewController,
        to toVC: UIViewController,
        context: Context
    ) -> UIPopAnimationControllerType?
}

@available(iOS 14.0, *)
extension DestinationLinkPopTransitionRepresentable {

    public func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerForPop animationController: UIViewControllerAnimatedTransitioning,
        context: Context
    ) -> UIViewControllerInteractiveTransitioning? {
        return animationController as? UIViewControllerInteractiveTransitioning
    }
}

@frozen
@available(iOS 14.0, *)
public struct DestinationLinkDefaultPopTransition: DestinationLinkPopTransitionRepresentable {

    public func navigationController(
        _ navigationController: UINavigationController,
        popping fromVC: UIViewController,
        to toVC: UIViewController,
        context: Context
    ) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}

@available(iOS 14.0, *)
extension DestinationLinkPopTransitionRepresentable where Self == DestinationLinkDefaultPopTransition {
    public static var `default`: DestinationLinkDefaultPopTransition { .init() }
}

#endif
