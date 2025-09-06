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
        insetSafeAreaByCornerRadius: Bool = true,
        preferredAspectRatio: CGFloat? = 1,
        preferredPresentationShadow: ShadowOptions? = nil,
        preferredBackground: BackgroundOptions? = nil,
        hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .card(
            .init(
                preferredEdgeInset: preferredEdgeInset,
                preferredCornerRadius: preferredCornerRadius,
                insetSafeAreaByCornerRadius: insetSafeAreaByCornerRadius,
                preferredAspectRatio: preferredAspectRatio,
                preferredPresentationShadow: preferredPresentationShadow ?? (preferredPresentationBackgroundColor == .clear || preferredBackground?.effect != nil ? .clear : .minimal),
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
        public var insetSafeAreaByCornerRadius: Bool = true
        /// A `nil` aspect ratio will size the cards height to it's ideal size
        public var preferredAspectRatio: CGFloat?
        public var preferredPresentationShadow: ShadowOptions?
        public var preferredBackground: BackgroundOptions?
        public var hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle?

        public init(
            preferredEdgeInset: CGFloat? = nil,
            preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
            insetSafeAreaByCornerRadius: Bool = true,
            preferredAspectRatio: CGFloat? = 1,
            preferredPresentationShadow: ShadowOptions? = nil,
            preferredBackground: BackgroundOptions? = nil,
            hapticsStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil
        ) {
            self.preferredEdgeInset = preferredEdgeInset
            self.preferredCornerRadius = preferredCornerRadius
            self.insetSafeAreaByCornerRadius = insetSafeAreaByCornerRadius
            self.preferredAspectRatio = preferredAspectRatio
            self.preferredPresentationShadow = preferredPresentationShadow
            self.preferredBackground = preferredBackground
            self.hapticsStyle = hapticsStyle
        }
    }
    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }

    public static let defaultEdgeInset: CGFloat = {
        if #available(iOS 26.0, *) {
            return 8
        }
        return 4
    }()
    public static let defaultCornerRadius: CGFloat = UIScreen.main.displayCornerRadius(min: 36)
    public static let defaultAdjustedCornerRadius: CornerRadiusOptions.RoundedRectangle = .rounded(cornerRadius: defaultCornerRadius - defaultEdgeInset, style: .continuous)

    public func makeUIPresentationController(
        presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController,
        context: Context
    ) -> CardPresentationController {
        let presentationController = CardPresentationController(
            preferredEdgeInset: options.preferredEdgeInset,
            preferredCornerRadius: options.preferredCornerRadius,
            insetSafeAreaByCornerRadius: options.insetSafeAreaByCornerRadius,
            preferredAspectRatio: options.preferredAspectRatio,
            presentedViewController: presented,
            presenting: presenting
        )
        presentationController.dismissalHapticsStyle = options.hapticsStyle
        return presentationController
    }

    public func updateUIPresentationController(
        presentationController: CardPresentationController,
        context: Context
    ) {
        presentationController.preferredEdgeInset = options.preferredEdgeInset
        presentationController.preferredCornerRadius = options.preferredCornerRadius
        presentationController.insetSafeAreaByCornerRadius = options.insetSafeAreaByCornerRadius
        presentationController.preferredAspectRatio = options.preferredAspectRatio
        presentationController.dismissalHapticsStyle = options.hapticsStyle
    }

    public func updateHostingController<Content>(
        presenting: PresentationHostingController<Content>,
        context: Context
    ) where Content: View {
        presenting.tracksContentSize = true
        presenting.preferredShadow = options.preferredPresentationShadow
        presenting.preferredBackground = options.preferredBackground
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        presentationController: UIPresentationController,
        context: Context
    ) -> CardPresentationControllerTransition? {
        let transition = CardPresentationControllerTransition(
            preferredEdgeInset: options.preferredEdgeInset,
            preferredCornerRadius: options.preferredCornerRadius,
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
    ) -> CardPresentationControllerTransition? {
        let transition = CardPresentationControllerTransition(
            preferredEdgeInset: options.preferredEdgeInset,
            preferredCornerRadius: options.preferredCornerRadius,
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
