//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// The transition and presentation style for a ``DestinationLink`` or ``DestinationLinkModifier``.
@available(iOS 14.0, *)
public struct DestinationLinkTransition: Sendable {

    @frozen
    public enum Value: Sendable {
        case `default`
        case zoom(ZoomDestinationLinkTransition.Options)
        case representable(any DestinationLinkTransitionRepresentable)
    }

    public var value: Value
    public var options: Options

    @inlinable
    public init(
        value: Value,
        options: Options = .init()
    ) {
        self.value = value
        self.options = options
    }

    @inlinable
    public func isInteractive(_ isInteractive: Bool) -> DestinationLinkTransition {
        var copy = self
        copy.options.isInteractive = isInteractive
        return copy
    }

    @inlinable
    public func preferredColorScheme(_ preferredColorScheme: ColorScheme?) -> DestinationLinkTransition {
        var copy = self
        copy.options.preferredPresentationColorScheme = preferredColorScheme
        return copy
    }
}


@available(iOS 14.0, *)
extension DestinationLinkTransition {

    /// The default presentation style of the `UINavigationController`.
    public static let `default` = DestinationLinkTransition(value: .default)

    /// The default presentation style of the `UINavigationController`.
    public static func `default`(
        options: DestinationLinkTransition.Options
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(
            value: .default,
            options: options
        )
    }

    /// A custom presentation style.
    public static func custom<T: DestinationLinkTransitionRepresentable>(
        _ transition: T
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(
            value: .representable(transition)
        )
    }

    /// A custom presentation style.
    public static func custom<T: DestinationLinkTransitionRepresentable>(
        options: DestinationLinkTransition.Options,
        _ transition: T
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(
            value: .representable(transition),
            options: options
        )
    }
}

@available(iOS 14.0, *)
extension DestinationLinkTransition {
    /// The transition options.
    @frozen
    public struct Options {
        /// Used when the presentation delegate asks if it should dismiss
        public var isInteractive: Bool
        /// When `true` a regular pan gesture anywhere on the destination view can begin a pop
        ///
        /// > Note: Does not work with the `.default` transition, use `.push` instead
        public var prefersPanGesturePop: Bool
        /// When `true`, the destination will be dismissed when the presentation source is dismantled
        public var shouldAutomaticallyDismissDestination: Bool
        /// When `true`, the `isPresented` binding is updated when dismissal begins, allowing
        /// for view updates alongside the transition.
        public var shouldTransitionIsPresentedAlongsideTransition: Bool
        public var preferredPresentationColorScheme: ColorScheme?
        public var preferredPresentationBackgroundColor: Color?
        public var isNavigationBarHidden: Bool?
        public var hidesBottomBarWhenPushed: Bool
        public var hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle?

        public init(
            isInteractive: Bool = true,
            prefersPanGesturePop: Bool = {
                if #available(iOS 26.0, *) {
                    return true
                }
                return false
            }(),
            shouldAutomaticallyDismissDestination: Bool = true,
            shouldTransitionIsPresentedAlongsideTransition: Bool = true,
            preferredPresentationColorScheme: ColorScheme? = nil,
            preferredPresentationBackgroundColor: Color? = nil,
            isNavigationBarHidden: Bool? = nil,
            hidesBottomBarWhenPushed: Bool = false,
            hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil
        ) {
            self.isInteractive = isInteractive
            self.prefersPanGesturePop = prefersPanGesturePop
            self.shouldAutomaticallyDismissDestination = shouldAutomaticallyDismissDestination
            self.shouldTransitionIsPresentedAlongsideTransition = shouldTransitionIsPresentedAlongsideTransition
            self.preferredPresentationColorScheme = preferredPresentationColorScheme
            self.preferredPresentationBackgroundColor = preferredPresentationBackgroundColor
            self.isNavigationBarHidden = isNavigationBarHidden
            self.hidesBottomBarWhenPushed = hidesBottomBarWhenPushed
            self.hapticsStyle = hapticsStyle
        }

        var preferredPresentationBackgroundUIColor: UIColor? {
            switch preferredPresentationBackgroundColor {
            case .clear:
                return .clear
            default:
                return preferredPresentationBackgroundColor?.toUIColor()
            }
        }
    }
}

#endif
