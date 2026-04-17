//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension DestinationLinkTransition {

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static let zoom: DestinationLinkTransition = .zoom()

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static func zoom(
        dimmingColor: Color? = nil,
        dimmingVisualEffect: UIBlurEffect.Style? = nil,
        prefersScalePresentingView: Bool = true,
        hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> DestinationLinkTransition {
        .zoom(
            .init(
                dimmingColor: dimmingColor,
                dimmingVisualEffect: dimmingVisualEffect,
                prefersScalePresentingView: prefersScalePresentingView
            ),
            options: .init(
                isInteractive: isInteractive,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor,
                hapticsStyle: hapticsStyle
            )
        )
    }

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static func zoom(
        _ transitionOptions: ZoomDestinationLinkTransition.Options,
        options: DestinationLinkTransition.Options = .init()
    ) -> DestinationLinkTransition {
        DestinationLinkTransition(
            value: .zoom(transitionOptions),
            options: options
        )
    }

    /// The zoom presentation style if available, otherwise the default transition style.
    public static var zoomIfAvailable: DestinationLinkTransition {
        if #available(iOS 18.0, *) {
            return .zoom
        }
        return .default
    }

    /// The zoom presentation style if available, otherwise a fallback transition style.
    public static func zoomIfAvailable(
        _ transitionOptions: ZoomDestinationLinkTransition.Options,
        options: DestinationLinkTransition.Options = .init(),
        otherwise fallback: DestinationLinkTransition = .default
    ) -> DestinationLinkTransition {
        if #available(iOS 18.0, *) {
            return .zoom(transitionOptions, options: options)
        }
        return fallback
    }
}

/// The transition options for a zoom transition.
@frozen
public struct ZoomDestinationLinkTransition: Sendable {

    @frozen
    public struct Options: Sendable {
        private var options: ZoomTransitionOptions

        public var dimmingColor: Color? {
            get { options.dimmingColor }
            set { options.dimmingColor = newValue }
        }

        public var dimmingVisualEffect: UIBlurEffect.Style? {
            get { options.dimmingVisualEffect }
            set { options.dimmingVisualEffect = newValue }
        }

        public var prefersScalePresentingView: Bool {
            get { options.prefersScalePresentingView }
            set { options.prefersScalePresentingView = newValue }
        }

        public init(
            dimmingColor: Color? = nil,
            dimmingVisualEffect: UIBlurEffect.Style? = nil,
            prefersScalePresentingView: Bool = true
        ) {
            self.options = ZoomTransitionOptions(
                dimmingColor: dimmingColor,
                dimmingVisualEffect: dimmingVisualEffect,
                prefersScalePresentingView: prefersScalePresentingView
            )
        }

        @MainActor @preconcurrency
        @available(iOS 18.0, *)
        func toUIKit() -> UIViewController.Transition.ZoomOptions {
            options.toUIKit()
        }
    }

    public var options: Options

    public init(options: Options) {
        self.options = options
    }
}

#endif
