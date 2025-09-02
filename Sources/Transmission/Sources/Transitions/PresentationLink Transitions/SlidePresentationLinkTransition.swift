//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    /// The slide presentation style.
    public static let slide: PresentationLinkTransition = .slide()

    /// The slide presentation style.
    public static func slide(
        _ transitionOptions: SlidePresentationLinkTransition.Options,
        options: PresentationLinkTransition.Options = .init(
            modalPresentationCapturesStatusBarAppearance: true
        )
    ) -> PresentationLinkTransition {
        .custom(
            options: options,
            SlidePresentationLinkTransition(options: transitionOptions)
        )
    }

    /// The slide presentation style.
    public static func slide(
        edge: Edge = .bottom,
        prefersScaleEffect: Bool = true,
        preferredFromCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
        preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
        preferredPresentationShadow: ShadowOptions? = nil,
        preferredBackground: BackgroundOptions? = nil,
        hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .slide(
            .init(
                edge: edge,
                prefersScaleEffect: prefersScaleEffect,
                preferredFromCornerRadius: preferredFromCornerRadius,
                preferredToCornerRadius: preferredToCornerRadius,
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
}

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    /// The slide presentation style.
    @available(*, deprecated, message: "Use `CornerRadiusOptions`")
    public static func slide(
        edge: Edge = .bottom,
        prefersScaleEffect: Bool = true,
        preferredFromCornerRadius: CGFloat?,
        preferredToCornerRadius: CGFloat?,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .slide(
            edge: edge,
            prefersScaleEffect: prefersScaleEffect,
            preferredFromCornerRadius: preferredFromCornerRadius.map { .rounded(cornerRadius: $0) },
            preferredToCornerRadius: preferredToCornerRadius.map { .rounded(cornerRadius: $0) },
            isInteractive: isInteractive,
            preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
        )
    }
}

@frozen
@available(iOS 14.0, *)
public struct SlidePresentationLinkTransition: PresentationLinkTransitionRepresentable {

    /// The transition options for a slide transition.
    @frozen
    public struct Options {

        public var edge: Edge
        public var prefersScaleEffect: Bool
        public var preferredFromCornerRadius: CornerRadiusOptions.RoundedRectangle?
        public var preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle?
        public var preferredPresentationShadow: ShadowOptions?
        public var preferredBackground: BackgroundOptions?
        public var hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle?

        public init(
            edge: Edge = .bottom,
            prefersScaleEffect: Bool = true,
            preferredFromCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
            preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
            preferredPresentationShadow: ShadowOptions? = nil,
            preferredBackground: BackgroundOptions? = nil,
            hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil
        ) {
            self.edge = edge
            self.prefersScaleEffect = prefersScaleEffect
            self.preferredFromCornerRadius = preferredFromCornerRadius
            self.preferredToCornerRadius = preferredToCornerRadius
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
    ) -> SlidePresentationController {
        let presentationController = SlidePresentationController(
            edge: options.edge,
            presentedViewController: presented,
            presenting: presenting
        )
        presentationController.preferredShadow = options.preferredPresentationShadow
        presentationController.presentedContainerView.preferredBackground = options.preferredBackground
        presentationController.dismissalHapticsStyle = options.hapticsStyle
        return presentationController
    }

    public func updateUIPresentationController(
        presentationController: SlidePresentationController,
        context: Context
    ) {
        presentationController.edge = options.edge
        presentationController.preferredShadow = options.preferredPresentationShadow
        presentationController.presentedContainerView.preferredBackground = options.preferredBackground
        presentationController.dismissalHapticsStyle = options.hapticsStyle
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        presentationController: UIPresentationController,
        context: Context
    ) -> SlidePresentationControllerTransition? {
        let transition = SlidePresentationControllerTransition(
            edge: options.edge,
            prefersScaleEffect: options.prefersScaleEffect,
            preferredFromCornerRadius: options.preferredFromCornerRadius,
            preferredToCornerRadius: options.preferredToCornerRadius,
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
    ) -> SlidePresentationControllerTransition? {
        let transition = SlidePresentationControllerTransition(
            edge: options.edge,
            prefersScaleEffect: options.prefersScaleEffect,
            preferredFromCornerRadius: options.preferredFromCornerRadius,
            preferredToCornerRadius: options.preferredToCornerRadius,
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
