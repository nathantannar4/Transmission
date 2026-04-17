//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import EngineCore

/// The transition and presentation style for a ``PresentationLink`` or ``PresentationLinkModifier``.
@available(iOS 14.0, *)
@frozen
public struct PresentationLinkTransition: Sendable {

    @frozen
    public enum Value: Sendable {
        case `default`
        case sheet(SheetPresentationLinkTransition.Options)
        case currentContext
        case fullscreen
        case popover(PopoverPresentationLinkTransition.Options)
        case zoom(ZoomPresentationLinkTransition.Options)
        case representable(any PresentationLinkTransitionRepresentable)
    }
    public var value: Value
    public var options: Options

    @inlinable
    public init(value: Value, options: Options = .init()) {
        self.value = value
        self.options = options
    }

    @inlinable
    public func isInteractive(_ isInteractive: Bool) -> PresentationLinkTransition {
        var copy = self
        copy.options.isInteractive = isInteractive
        return copy
    }

    @inlinable
    public func preferredColorScheme(_ preferredColorScheme: ColorScheme?) -> PresentationLinkTransition {
        var copy = self
        copy.options.preferredPresentationColorScheme = preferredColorScheme
        return copy
    }
}

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    /// The default presentation style of the `UIViewController`.
    public static let `default` = PresentationLinkTransition(value: .default)

    /// The default presentation style of the `UIViewController`.
    public static func `default`(
        options: PresentationLinkTransition.Options
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .default, options: options)
    }

    /// The current context presentation style.
    public static let currentContext = PresentationLinkTransition(value: .currentContext)

    /// The current context presentation style.
    public static func currentContext(
        options: PresentationLinkTransition.Options
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .currentContext, options: options)
    }

    /// The fullscreen presentation style.
    public static let fullscreen = PresentationLinkTransition(value: .fullscreen)

    /// The fullscreen presentation style.
    public static func fullscreen(
        options: PresentationLinkTransition.Options
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(value: .fullscreen, options: options)
    }

    /// A custom presentation style.
    public static func custom<
        T: PresentationLinkTransitionRepresentable
    >(
        _ transition: T
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(
            value: .representable(transition)
        )
    }

    /// A custom presentation style.
    public static func custom<
        T: PresentationLinkTransitionRepresentable
    >(
        options: PresentationLinkTransition.Options,
        _ transition: T
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(
            value: .representable(transition),
            options: options
        )
    }
}

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    public typealias Shadow = ShadowOptions

    /// The transition options.
    @frozen
    public struct Options: Sendable {
        /// Used when the presentation delegate asks if it should dismiss
        public var isInteractive: Bool
        /// When `true`, the destination will not be deallocated when dismissed and instead reused for subsequent presentations.
        public var isDestinationReusable: Bool
        /// When `true`, the destination will be dismissed when the presentation source is dismantled
        public var shouldAutomaticallyDismissDestination: Bool
        /// When `true`, the `isPresented` binding is updated when dismissal begins, allowing
        /// for view updates alongside the transition.
        public var shouldTransitionIsPresentedAlongsideTransition: Bool
        /// When `true`, the destination will be presented after dismissing the view the presentation source is already presenting.
        public var shouldAutomaticallyDismissPresentedView: Bool
        public var modalPresentationCapturesStatusBarAppearance: Bool
        public var preferredPresentationColorScheme: ColorScheme?
        public var preferredPresentationSafeAreaInsets: EdgeInsets?
        public var preferredPresentationBackgroundColor: Color?

        public init(
            isInteractive: Bool = true,
            isDestinationReusable: Bool = false,
            shouldAutomaticallyDismissDestination: Bool = true,
            shouldTransitionIsPresentedAlongsideTransition: Bool = true,
            shouldAutomaticallyDismissPresentedView: Bool = true,
            modalPresentationCapturesStatusBarAppearance: Bool = false,
            preferredPresentationColorScheme: ColorScheme? = nil,
            preferredPresentationSafeAreaInsets: EdgeInsets? = nil,
            preferredPresentationBackgroundColor: Color? = nil
        ) {
            self.isInteractive = isInteractive
            self.isDestinationReusable = isDestinationReusable
            self.shouldAutomaticallyDismissDestination = shouldAutomaticallyDismissDestination
            self.shouldTransitionIsPresentedAlongsideTransition = shouldTransitionIsPresentedAlongsideTransition
            self.shouldAutomaticallyDismissPresentedView = shouldAutomaticallyDismissPresentedView
            self.modalPresentationCapturesStatusBarAppearance = modalPresentationCapturesStatusBarAppearance
            self.preferredPresentationColorScheme = preferredPresentationColorScheme
            self.preferredPresentationSafeAreaInsets = preferredPresentationSafeAreaInsets
            self.preferredPresentationBackgroundColor = preferredPresentationBackgroundColor
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
