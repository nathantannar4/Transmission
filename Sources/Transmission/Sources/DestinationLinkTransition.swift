//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// The transition and presentation style for a ``DestinationLink`` or ``DestinationLinkModifier``.
@available(iOS 14.0, *)
@MainActor @preconcurrency
public struct DestinationLinkTransition: Sendable {

    @MainActor @preconcurrency
    enum Value: @unchecked Sendable {
        case `default`(Options)
        case zoom(ZoomOptions)
        case representable(Options, any DestinationLinkTransitionRepresentable)

        var options: Options {
            switch self {
            case .zoom(let options):
                return options.options
            case .default(let options), .representable(let options, _):
                return options
            }
        }
    }
    var value: Value

    /// The default presentation style of the `UINavigationController`.
    public static let `default`: DestinationLinkTransition = DestinationLinkTransition(value: .default(.init()))

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static let zoom = DestinationLinkTransition(value: .zoom(.init()))

    /// The zoom presentation style if available, otherwise the default transition style.
    public static var zoomIfAvailable: DestinationLinkTransition {
        if #available(iOS 18.0, *) {
            return .zoom
        }
        return .default
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
        /// Used when the presentation delegate asks if it should dismiss
        public var isInteractive: Bool
        /// When `true` a regular pan gesture anywhere on the destination view can begin a pop
        ///
        /// > Note: Does not work with the `.default` transition, use `.push` instead
        public var prefersPanGesturePop: Bool
        /// When `true`, the destination will be dismissed when the presentation source is dismantled
        public var shouldAutomaticallyDismissDestination: Bool
        public var preferredPresentationColorScheme: ColorScheme?
        public var preferredPresentationBackgroundColor: Color?
        public var isNavigationBarHidden: Bool?
        public var hidesBottomBarWhenPushed: Bool
        public var hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle?

        public init(
            isInteractive: Bool = true,
            prefersPanGesturePop: Bool = false,
            shouldAutomaticallyDismissDestination: Bool = true,
            preferredPresentationColorScheme: ColorScheme? = nil,
            preferredPresentationBackgroundColor: Color? = nil,
            isNavigationBarHidden: Bool? = nil,
            hidesBottomBarWhenPushed: Bool = false,
            hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil
        ) {
            self.isInteractive = isInteractive
            self.prefersPanGesturePop = prefersPanGesturePop
            self.shouldAutomaticallyDismissDestination = shouldAutomaticallyDismissDestination
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

    /// The transition options for a zoom transition.
    @frozen
    @MainActor @preconcurrency
    public struct ZoomOptions {
        public var options: Options
        public var dimmingColor: Color?
        public var dimmingVisualEffect: UIBlurEffect.Style?
        public var hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle?

        public init(
            dimmingColor: Color? = nil,
            dimmingVisualEffect: UIBlurEffect.Style? = nil,
            hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
            options: Options = .init()
        ) {
            self.options = options
            self.dimmingColor = dimmingColor
            self.dimmingVisualEffect = dimmingVisualEffect
            self.hapticsStyle = hapticsStyle
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

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static func zoom(
        dimmingColor: Color? = nil,
        dimmingVisualEffect: UIBlurEffect.Style? = nil,
        hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(
            value: .zoom(
                .init(
                    dimmingColor: dimmingColor,
                    dimmingVisualEffect: dimmingVisualEffect,
                    options: .init(
                        isInteractive: isInteractive,
                        preferredPresentationBackgroundColor: preferredPresentationBackgroundColor,
                        hapticsStyle: hapticsStyle
                    )
                )
            )
        )
    }

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static func zoom(
        options: ZoomOptions
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .zoom(options))
    }

    /// The zoom presentation style if available, otherwise a fallback transition style.
    public static func zoomIfAvailable(
        options: ZoomOptions,
        otherwise fallback: DestinationLinkTransition = .default
    ) -> DestinationLinkTransition {
        if #available(iOS 18.0, *) {
            return .zoom(options: options)
        }
        return fallback
    }

    /// A custom presentation style.
    public static func custom<T: DestinationLinkTransitionRepresentable>(
        options: DestinationLinkTransition.Options,
        _ transition: T
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(value: .representable(options, transition))
    }
}

#endif
