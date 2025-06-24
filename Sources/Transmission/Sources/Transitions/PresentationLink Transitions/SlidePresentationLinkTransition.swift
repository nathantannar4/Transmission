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
                preferredPresentationShadow: preferredPresentationBackgroundColor == .clear ? .clear : .minimal,
                hapticsStyle: hapticsStyle
            ),
            options: .init(
                isInteractive: isInteractive,
                modalPresentationCapturesStatusBarAppearance: true,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
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
        public var preferredPresentationShadow: ShadowOptions
        public var hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle?

        public init(
            edge: Edge = .bottom,
            prefersScaleEffect: Bool = true,
            preferredFromCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
            preferredToCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
            preferredPresentationShadow: ShadowOptions = .minimal,
            hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil
        ) {
            self.edge = edge
            self.prefersScaleEffect = prefersScaleEffect
            self.preferredFromCornerRadius = preferredFromCornerRadius
            self.preferredToCornerRadius = preferredToCornerRadius
            self.preferredPresentationShadow = preferredPresentationShadow
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
        context: Context
    ) -> SlidePresentationController {
        let presentationController = SlidePresentationController(
            edge: options.edge,
            presentedViewController: presented,
            presenting: presenting
        )
        presentationController.presentedViewShadow = options.preferredPresentationShadow
        presentationController.dismissalHapticsStyle = options.hapticsStyle
        return presentationController
    }

    public func updateUIPresentationController(
        presentationController: SlidePresentationController,
        context: Context
    ) {
        presentationController.edge = options.edge
        presentationController.presentedViewShadow = options.preferredPresentationShadow
        presentationController.dismissalHapticsStyle = options.hapticsStyle
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
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
        transition.wantsInteractiveStart = false
        return transition
    }

    public func animationController(
        forDismissed dismissed: UIViewController,
        context: Context
    ) -> SlidePresentationControllerTransition? {
        guard let presentationController = dismissed.presentationController as? InteractivePresentationController else {
            return nil
        }
        let animation: Animation? = {
            guard context.transaction.animation == .default else {
                return context.transaction.animation
            }
            return presentationController.preferredDefaultAnimation() ?? context.transaction.animation
        }()
        let transition = SlidePresentationControllerTransition(
            edge: options.edge,
            prefersScaleEffect: options.prefersScaleEffect,
            preferredFromCornerRadius: options.preferredFromCornerRadius,
            preferredToCornerRadius: options.preferredToCornerRadius,
            isPresenting: false,
            animation: animation
        )
        transition.wantsInteractiveStart = presentationController.wantsInteractiveTransition
        presentationController.transition(with: transition)
        return transition
    }
}

#endif
