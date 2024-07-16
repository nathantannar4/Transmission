//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// The transition and presentation style for a ``DestinationLink`` or ``DestinationLinkModifier``.
@available(iOS 14.0, *)
public struct DestinationLinkTransition: Sendable {
    enum Value: @unchecked Sendable {
        case `default`(Options)
        case representable(Options, any DestinationLinkTransitionRepresentable)

        @available(*, deprecated)
        case custom(Options, DestinationLinkCustomTransition)

        var options: Options {
            switch self {
            case .default(let options):
                return options
            case .custom(let options, _):
                return options
            case .representable(let options, _):
                return options
            }
        }
    }
    var value: Value

    /// The default presentation style of the `UINavigationController`.
    public static let `default`: DestinationLinkTransition = DestinationLinkTransition(value: .default(.init()))

    /// A custom presentation style.
    @available(*, deprecated)
    public static func custom<T: DestinationLinkCustomTransition>(_ transition: T) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .custom(.init(), transition))
    }

    /// A custom presentation style.
    public static func custom<T: DestinationLinkTransitionRepresentable>(_ transition: T) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .representable(.init(), transition))
    }
}

@available(iOS 14.0, *)
extension DestinationLinkTransition {
    /// The transition options.
    @frozen
    public struct Options {
        /// When `true`, the destination will be dismissed when the presentation source is dismantled
        public var shouldAutomaticallyDismissDestination: Bool
        public var preferredPresentationBackgroundColor: Color?

        public init(
            shouldAutomaticallyDismissDestination: Bool = true,
            preferredPresentationBackgroundColor: Color? = nil
        ) {
            self.shouldAutomaticallyDismissDestination = shouldAutomaticallyDismissDestination
            self.preferredPresentationBackgroundColor = preferredPresentationBackgroundColor
        }

        var preferredPresentationBackgroundUIColor: UIColor? {
            preferredPresentationBackgroundColor?.toUIColor()
        }
    }
}

@available(iOS 14.0, *)
extension DestinationLinkTransition {
    /// The default presentation style of the `UINavigationController`.
    public static func `default`(
        options: DestinationLinkTransition.Options
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .default(options))
    }

    /// A custom presentation style.
    @available(*, deprecated)
    public static func custom<T: DestinationLinkCustomTransition>(
        options: DestinationLinkTransition.Options,
        _ transition: T
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .custom(options, transition))
    }

    /// A custom presentation style.
    public static func custom<T: DestinationLinkTransitionRepresentable>(
        options: DestinationLinkTransition.Options,
        _ transition: T
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .representable(options, transition))
    }
}

@available(iOS 14.0, *)
@available(*, deprecated, renamed: "DestinationLinkTransitionRepresentable")
@MainActor @preconcurrency
public protocol DestinationLinkCustomTransition {

    /// The interaction controller to use for the transition presentation.
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    ///
    @MainActor @preconcurrency func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning?

    /// The animation controller to use for the transition presentation.
    @MainActor @preconcurrency func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController,
        sourceView: UIView
    ) -> UIViewControllerAnimatedTransitioning
}

@available(iOS 14.0, *)
@available(*, deprecated, renamed: "DestinationLinkTransitionRepresentable")
extension DestinationLinkCustomTransition {

    public func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}

#endif
