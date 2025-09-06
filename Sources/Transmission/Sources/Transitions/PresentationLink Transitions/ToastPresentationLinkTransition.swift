//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    /// The toast presentation style.
    public static let toast: PresentationLinkTransition = .toast()

    /// The toast presentation style.
    public static func toast(
        _ transitionOptions: ToastPresentationLinkTransition.Options,
        options: PresentationLinkTransition.Options = .init()
    ) -> PresentationLinkTransition {
        .custom(
            options: options,
            ToastPresentationLinkTransition(options: transitionOptions)
        )
    }

    /// The toast presentation style.
    public static func toast(
        edge: Edge = .bottom,
        preferredCornerRadius: CornerRadiusOptions? = nil,
        preferredPresentationShadow: ShadowOptions? = nil,
        preferredBackground: BackgroundOptions? = nil,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .toast(
            .init(
                edge: edge,
                preferredCornerRadius: preferredCornerRadius,
                preferredPresentationShadow: preferredPresentationShadow ?? (preferredPresentationBackgroundColor == .clear || preferredBackground?.effect != nil ? .clear : .minimal),
                preferredBackground: preferredBackground,
            ),
            options: .init(
                isInteractive: isInteractive,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor ?? (preferredBackground != nil ? .clear : nil)
            )
        )
    }
}

@frozen
@available(iOS 14.0, *)
public struct ToastPresentationLinkTransition: PresentationLinkTransitionRepresentable {

    /// The transition options for a toast transition.
    @frozen
    public struct Options {

        public var edge: Edge
        public var preferredCornerRadius: CornerRadiusOptions?
        public var preferredPresentationShadow: ShadowOptions?
        public var preferredBackground: BackgroundOptions?

        public init(
            edge: Edge = .bottom,
            preferredCornerRadius: CornerRadiusOptions? = nil,
            preferredPresentationShadow: ShadowOptions? = nil,
            preferredBackground: BackgroundOptions? = nil
        ) {
            self.edge = edge
            self.preferredCornerRadius = preferredCornerRadius
            self.preferredPresentationShadow = preferredPresentationShadow
            self.preferredBackground = preferredBackground
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
    ) -> ToastPresentationController {
        let presentationController = ToastPresentationController(
            edge: options.edge,
            preferredCornerRadius: options.preferredCornerRadius,
            presentedViewController: presented,
            presenting: presenting
        )
        return presentationController
    }

    public func updateUIPresentationController(
        presentationController: ToastPresentationController,
        context: Context
    ) {
        presentationController.edge = options.edge
        presentationController.preferredCornerRadius = options.preferredCornerRadius
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
    ) -> ToastPresentationControllerTransition? {
        let transition = ToastPresentationControllerTransition(
            edge: options.edge,
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
    ) -> ToastPresentationControllerTransition? {
        let transition = ToastPresentationControllerTransition(
            edge: options.edge,
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
