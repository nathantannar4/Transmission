//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    /// The matched geometry presentation style.
    public static let matchedGeometry: PresentationLinkTransition = .matchedGeometry()

    /// The matched geometry presentation style.
    public static func matchedGeometry(
        _ transitionOptions: MatchedGeometryPresentationLinkTransition.Options,
        options: PresentationLinkTransition.Options = .init()
    ) -> PresentationLinkTransition {
        .custom(
            options: options,
            MatchedGeometryPresentationLinkTransition(options: transitionOptions)
        )
    }

    /// The matched geometry presentation style.
    public static func matchedGeometry(
        preferredFromCornerRadius: CornerRadiusOptions? = nil,
        preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
        prefersScaleEffect: Bool = false,
        prefersZoomEffect: Bool = false,
        minimumScaleFactor: CGFloat = 0.5,
        initialOpacity: CGFloat = 1,
        preferredPresentationShadow: ShadowOptions? = nil,
        preferredBackground: BackgroundOptions? = nil,
        hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .matchedGeometry(
            .init(
                preferredFromCornerRadius: preferredFromCornerRadius,
                preferredToCornerRadius: preferredToCornerRadius,
                prefersScaleEffect: prefersScaleEffect,
                prefersZoomEffect: prefersZoomEffect,
                minimumScaleFactor: minimumScaleFactor,
                initialOpacity: initialOpacity,
                preferredPresentationShadow: preferredPresentationShadow ?? (preferredPresentationBackgroundColor == .clear ? .clear : .minimal),
                preferredBackground: preferredBackground,
                hapticsStyle: hapticsStyle
            ),
            options: .init(
                isInteractive: isInteractive,
                modalPresentationCapturesStatusBarAppearance: true,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor ?? (preferredBackground != nil ? .clear : nil)
            )
        )
    }

    /// The matched geometry zoom presentation style.
    public static let matchedGeometryZoom: PresentationLinkTransition = .matchedGeometryZoom()

    /// The matched geometry zoom presentation style.
    public static func matchedGeometryZoom(
        preferredFromCornerRadius: CornerRadiusOptions? = nil,
        minimumScaleFactor: CGFloat = 0.5,
        preferredPresentationShadow: ShadowOptions? = nil,
        preferredBackground: BackgroundOptions? = nil,
        hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .matchedGeometry(
            preferredFromCornerRadius: preferredFromCornerRadius,
            prefersScaleEffect: true,
            prefersZoomEffect: true,
            minimumScaleFactor: minimumScaleFactor,
            initialOpacity: 0,
            preferredPresentationShadow: preferredPresentationShadow,
            preferredBackground: preferredBackground,
            hapticsStyle: hapticsStyle,
            isInteractive: isInteractive,
            preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
        )
    }
}

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    /// The matched geometry presentation style.
    @available(*, deprecated, message: "Use `CornerRadiusOptions`")
    public static func matchedGeometry(
        preferredCornerRadius: CGFloat,
        prefersScaleEffect: Bool = false,
        prefersZoomEffect: Bool = false,
        minimumScaleFactor: CGFloat = 0.5,
        initialOpacity: CGFloat = 1,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .matchedGeometry(
            preferredFromCornerRadius: .rounded(cornerRadius: preferredCornerRadius),
            prefersScaleEffect: prefersScaleEffect,
            prefersZoomEffect: prefersZoomEffect,
            minimumScaleFactor: minimumScaleFactor,
            initialOpacity: initialOpacity,
            isInteractive: isInteractive,
            preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
        )
    }

    /// The matched geometry zoom presentation style.
    @available(*, deprecated, message: "Use `CornerRadiusOptions`")
    public static func matchedGeometryZoom(
        preferredCornerRadius: CGFloat
    ) -> PresentationLinkTransition {
        .matchedGeometryZoom(
            preferredFromCornerRadius: .rounded(cornerRadius: preferredCornerRadius)
        )
    }
}

@frozen
@available(iOS 14.0, *)
@MainActor @preconcurrency
public struct MatchedGeometryPresentationLinkTransition: PresentationLinkTransitionRepresentable {

    /// The transition options for a matched geometry transition.
    @frozen
    public struct Options {

        public var edges: Edge.Set
        public var preferredFromCornerRadius: CornerRadiusOptions?
        public var preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle?
        public var prefersScaleEffect: Bool
        public var prefersZoomEffect: Bool
        public var minimumScaleFactor: CGFloat
        public var initialOpacity: CGFloat
        public var preferredPresentationShadow: ShadowOptions?
        public var preferredBackground: BackgroundOptions?
        public var hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle?

        public init(
            edges: Edge.Set = .all,
            preferredFromCornerRadius: CornerRadiusOptions? = nil,
            preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
            prefersScaleEffect: Bool = false,
            prefersZoomEffect: Bool = false,
            minimumScaleFactor: CGFloat = 0.5,
            initialOpacity: CGFloat = 1,
            preferredPresentationShadow: ShadowOptions? = nil,
            preferredBackground: BackgroundOptions? = nil,
            hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil
        ) {
            self.edges = edges
            self.preferredFromCornerRadius = preferredFromCornerRadius
            self.preferredToCornerRadius = preferredToCornerRadius
            self.prefersScaleEffect = prefersScaleEffect
            self.prefersZoomEffect = prefersZoomEffect
            self.minimumScaleFactor = minimumScaleFactor
            self.initialOpacity = initialOpacity
            self.preferredPresentationShadow = preferredPresentationShadow
            self.preferredBackground = preferredBackground
            self.hapticsStyle = hapticsStyle
        }
    }
    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }

    public func makeUIPresentationController(
        presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController,
        context: Context
    ) -> MatchedGeometryPresentationController {
        let presentationController = MatchedGeometryPresentationController(
            edges: options.edges,
            minimumScaleFactor: options.minimumScaleFactor,
            presentedViewController: presented,
            presenting: presenting
        )
        presentationController.preferredShadow = options.preferredPresentationShadow
        presentationController.dismissalHapticsStyle = options.hapticsStyle
        presentationController.presentedContainerView.preferredBackground = options.preferredBackground
        return presentationController
    }

    public func updateUIPresentationController(
        presentationController: MatchedGeometryPresentationController,
        context: Context
    ) {
        presentationController.edges = options.edges
        presentationController.minimumScaleFactor = options.minimumScaleFactor
        presentationController.preferredShadow = options.preferredPresentationShadow
        presentationController.presentedContainerView.preferredBackground = options.preferredBackground
        presentationController.dismissalHapticsStyle = options.hapticsStyle
    }

    public func updateHostingController<Content>(
        presenting: PresentationHostingController<Content>,
        context: Context
    ) where Content: View {
        presenting.tracksContentSize = true
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        presentationController: UIPresentationController,
        context: Context
    ) -> MatchedGeometryPresentationControllerTransition? {
        let transition = MatchedGeometryPresentationControllerTransition(
            sourceView: context.sourceView,
            prefersScaleEffect: options.prefersScaleEffect,
            prefersZoomEffect: options.prefersZoomEffect,
            preferredFromCornerRadius: options.preferredFromCornerRadius,
            preferredToCornerRadius: options.preferredToCornerRadius,
            initialOpacity: options.initialOpacity,
            isPresenting: true,
            animation: context.transaction.animation
        )
        if let presentationController = presentationController as? PresentationController {
            presentationController.attach(to: transition)
        } else {
            transition.wantsInteractiveStart = false
        }
        return transition
    }

    public func animationController(
        forDismissed dismissed: UIViewController,
        presentationController: UIPresentationController,
        context: Context
    ) -> MatchedGeometryPresentationControllerTransition? {
        let transition = MatchedGeometryPresentationControllerTransition(
            sourceView: context.sourceView,
            prefersScaleEffect: options.prefersScaleEffect,
            prefersZoomEffect: options.prefersZoomEffect,
            preferredFromCornerRadius: options.preferredFromCornerRadius,
            preferredToCornerRadius: options.preferredToCornerRadius,
            initialOpacity: options.initialOpacity,
            isPresenting: false,
            animation: context.transaction.animation
        )
        if let presentationController = presentationController as? PresentationController {
            presentationController.attach(to: transition)
        } else {
            transition.wantsInteractiveStart = false
        }
        return transition
    }
}

#endif
