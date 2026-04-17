//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static let zoom: PresentationLinkTransition = .zoom()

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static func zoom(
        dimmingColor: Color? = nil,
        dimmingVisualEffect: UIBlurEffect.Style? = nil,
        prefersScalePresentingView: Bool = true,
        hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .zoom(
            .init(
                dimmingColor: dimmingColor,
                dimmingVisualEffect: dimmingVisualEffect,
                hapticsStyle: hapticsStyle,
                prefersScalePresentingView: prefersScalePresentingView
            ),
            options: .init(
                isInteractive: isInteractive,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
            )
        )
    }

    /// The zoom presentation style.
    @available(iOS 18.0, *)
    public static func zoom(
        _ transitionOptions: ZoomPresentationLinkTransition.Options,
        options: PresentationLinkTransition.Options = .init()
    ) -> PresentationLinkTransition {
        PresentationLinkTransition(
            value: .zoom(transitionOptions),
            options: options
        )
    }

    /// The zoom presentation style if available, otherwise a backwards compatible variant of the matched geometry presentation style.
    public static var zoomIfAvailable: PresentationLinkTransition {
        if #available(iOS 18.0, *) {
            return .zoom
        }
        return .matchedGeometryZoom
    }

    /// The zoom presentation style if available, otherwise a fallback transition style.
    public static func zoomIfAvailable(
        _ transitionOptions: ZoomPresentationLinkTransition.Options,
        options: PresentationLinkTransition.Options = .init(),
        otherwise fallback: PresentationLinkTransition
    ) -> PresentationLinkTransition {
        if #available(iOS 18.0, *) {
            return .zoom(transitionOptions, options: options)
        }
        return fallback
    }

    /// The zoom presentation style if available, otherwise a backwards compatible variant of the matched geometry presentation style.
    public static func zoomIfAvailable(
        _ transitionOptions: ZoomPresentationLinkTransition.Options,
        options: PresentationLinkTransition.Options = .init()
    ) -> PresentationLinkTransition {
        if #available(iOS 18.0, *) {
            return .zoom(transitionOptions, options: options)
        }
        return .matchedGeometry(
            .init(
                prefersScaleEffect: true,
                prefersZoomEffect: true,
                initialOpacity: 0,
                preferredPresentationShadow: options.preferredPresentationBackgroundColor == .clear ? .clear : .prominent
            ),
            options: options
        )
    }
}

@frozen
public struct ZoomPresentationLinkTransition: Sendable {

    /// The transition options for a zoom transition.
    @frozen
    public struct Options: Sendable {
        private var options: ZoomTransitionOptions
        public var hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle?

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
            hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
            prefersScalePresentingView: Bool = true
        ) {
            self.options = ZoomTransitionOptions(
                dimmingColor: dimmingColor,
                dimmingVisualEffect: dimmingVisualEffect,
                prefersScalePresentingView: prefersScalePresentingView
            )
            self.hapticsStyle = hapticsStyle
        }

        @MainActor @preconcurrency
        @available(iOS 18.0, *)
        func toUIKit() -> UIViewController.Transition.ZoomOptions {
            options.toUIKit()
        }
    }

    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }
}

#endif
