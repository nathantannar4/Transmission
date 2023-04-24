//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// The transition and presentation style for a ``DestinationLink`` or ``DestinationLinkModifier``.
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct DestinationLinkTransition {
    enum Value {
        case `default`
        case custom(DestinationLinkCustomTransition)
    }
    var value: Value

    /// The default presentation style of the `UINavigationController`.
    public static let `default`: DestinationLinkTransition = DestinationLinkTransition(value: .default)

    /// A custom presentation style.
    public static func custom<T: DestinationLinkCustomTransition>(_ transition: T) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .custom(transition))
    }
}

public protocol DestinationLinkCustomTransition {

    /// The interaction controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning?

    /// The animation controller to use for the transition presentation.
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController,
        sourceView: UIView
    ) -> UIViewControllerAnimatedTransitioning
}

extension DestinationLinkCustomTransition {

    public func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}

#endif
