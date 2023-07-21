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
        case `default`(Options)
        case custom(Options, DestinationLinkCustomTransition)

        var options: Options {
            switch self {
            case .default(let options):
                return options
            case .custom(let options, _):
                return options
            }
        }
    }
    var value: Value

    /// The default presentation style of the `UINavigationController`.
    public static let `default`: DestinationLinkTransition = DestinationLinkTransition(value: .default(.init()))

    /// A custom presentation style.
    public static func custom<T: DestinationLinkCustomTransition>(_ transition: T) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .custom(.init(), transition))
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
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
            guard let color = preferredPresentationBackgroundColor else {
                return nil
            }
            // Need to extract the UIColor since because SwiftUI's UIColor init
            // from a Color does not work for dynamic colors when set on UIView's
            let uiColor = Mirror(reflecting: color).children.lazy.compactMap({ child in
                Mirror(reflecting: child.value).children.first?.value as? UIColor
            }).first
            return uiColor ?? UIColor(color)
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension DestinationLinkTransition {
    /// The default presentation style of the `UINavigationController`.
    public static func `default`(
        options: DestinationLinkTransition.Options
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .default(options))
    }

    /// A custom presentation style.
    public static func custom<T: DestinationLinkCustomTransition>(
        options: DestinationLinkTransition.Options,
        _ transition: T
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .custom(options, transition))
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
