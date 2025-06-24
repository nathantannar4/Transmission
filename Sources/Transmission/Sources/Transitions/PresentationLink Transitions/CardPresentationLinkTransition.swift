//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    /// The card presentation style.
    public static let card: PresentationLinkTransition = .card()

    /// The card presentation style.
    public static func card(
        _ transitionOptions: CardPresentationLinkTransition.Options,
        options: PresentationLinkTransition.Options = .init(
            modalPresentationCapturesStatusBarAppearance: true
        )
    ) -> PresentationLinkTransition {
        .custom(
            options: options,
            CardPresentationLinkTransition(options: transitionOptions)
        )
    }

    /// The card presentation style.
    public static func card(
        preferredEdgeInset: CGFloat? = nil,
        preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
        preferredAspectRatio: CGFloat? = 1,
        hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .card(
            .init(
                preferredEdgeInset: preferredEdgeInset,
                preferredCornerRadius: preferredCornerRadius,
                preferredAspectRatio: preferredAspectRatio,
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

    /// The card presentation style.
    @available(*, deprecated, message: "Use `CornerRadiusOptions`")
    public static func card(
        preferredEdgeInset: CGFloat? = nil,
        preferredCornerRadius: CGFloat,
        preferredAspectRatio: CGFloat? = 1,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .card(
            preferredEdgeInset: preferredEdgeInset,
            preferredCornerRadius: .rounded(cornerRadius: preferredCornerRadius),
            preferredAspectRatio: preferredAspectRatio,
            isInteractive: isInteractive,
            preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
        )
    }
}

@frozen
@available(iOS 14.0, *)
public struct CardPresentationLinkTransition: PresentationLinkTransitionRepresentable {

    /// The transition options for a card transition.
    @frozen
    public struct Options {

        public var preferredEdgeInset: CGFloat?
        public var preferredCornerRadius: CornerRadiusOptions.RoundedRectangle?
        /// A `nil` aspect ratio will size the cards height to it's ideal size
        public var preferredAspectRatio: CGFloat?
        public var preferredPresentationShadow: ShadowOptions
        public var hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle?

        public init(
            preferredEdgeInset: CGFloat? = nil,
            preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
            preferredAspectRatio: CGFloat? = 1,
            preferredPresentationShadow: ShadowOptions = .minimal,
            hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil
        ) {
            self.preferredEdgeInset = preferredEdgeInset
            self.preferredCornerRadius = preferredCornerRadius
            self.preferredAspectRatio = preferredAspectRatio
            self.preferredPresentationShadow = preferredPresentationShadow
            self.hapticsStyle = hapticsStyle
        }
    }
    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }

    public static let defaultEdgeInset: CGFloat = 4
    public static let defaultCornerRadius: CGFloat = UIScreen.main.displayCornerRadius(min: 36)
    public static let defaultAdjustedCornerRadius: CornerRadiusOptions.RoundedRectangle = .rounded(cornerRadius: defaultCornerRadius - defaultEdgeInset, style: .continuous)

    public func makeUIPresentationController(
        presented: UIViewController,
        presenting: UIViewController?,
        context: Context
    ) -> CardPresentationController {
        let presentationController = CardPresentationController(
            preferredEdgeInset: options.preferredEdgeInset,
            preferredCornerRadius: options.preferredCornerRadius,
            preferredAspectRatio: options.preferredAspectRatio,
            presentedViewController: presented,
            presenting: presenting
        )
        presentationController.presentedViewShadow = options.preferredPresentationShadow
        presentationController.dismissalHapticsStyle = options.hapticsStyle
        return presentationController
    }

    public func updateUIPresentationController(
        presentationController: CardPresentationController,
        context: Context
    ) {
        presentationController.preferredEdgeInset = options.preferredEdgeInset
        presentationController.preferredCornerRadius = options.preferredCornerRadius
        presentationController.preferredAspectRatio = options.preferredAspectRatio
        presentationController.presentedViewShadow = options.preferredPresentationShadow
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
        context: Context
    ) -> CardPresentationControllerTransition? {
        let transition = CardPresentationControllerTransition(
            preferredEdgeInset: options.preferredEdgeInset,
            preferredCornerRadius: options.preferredCornerRadius,
            isPresenting: true,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = false
        return transition
    }

    public func animationController(
        forDismissed dismissed: UIViewController,
        context: Context
    ) -> CardPresentationControllerTransition? {
        guard let presentationController = dismissed.presentationController as? InteractivePresentationController else {
            return nil
        }
        let animation: Animation? = {
            guard context.transaction.animation == .default else {
                return context.transaction.animation
            }
            return presentationController.preferredDefaultAnimation() ?? context.transaction.animation
        }()
        let transition = CardPresentationControllerTransition(
            preferredEdgeInset: options.preferredEdgeInset,
            preferredCornerRadius: options.preferredCornerRadius,
            isPresenting: false,
            animation: animation
        )
        transition.wantsInteractiveStart = presentationController.wantsInteractiveTransition
        presentationController.transition(with: transition)
        return transition
    }
}

#endif
