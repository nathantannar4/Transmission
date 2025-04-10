//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 14.0, *)
extension PresentationLinkTransition {

    /// The card presentation style.
    public static var card: PresentationLinkTransition = .card()

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
        preferredCornerRadius: CGFloat? = nil,
        preferredAspectRatio: CGFloat? = 1,
        isInteractive: Bool = true,
        preferredPresentationBackgroundColor: Color? = nil
    ) -> PresentationLinkTransition {
        .card(
            .init(
                preferredEdgeInset: preferredEdgeInset,
                preferredCornerRadius: preferredCornerRadius,
                preferredAspectRatio: preferredAspectRatio,
                preferredPresentationShadow: preferredPresentationBackgroundColor == .clear ? .clear : .minimal
            ),
            options: .init(
                isInteractive: isInteractive,
                modalPresentationCapturesStatusBarAppearance: true,
                preferredPresentationBackgroundColor: preferredPresentationBackgroundColor
            )
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
        public var preferredCornerRadius: CGFloat?
        /// A `nil` aspect ratio will size the cards height to it's ideal size
        public var preferredAspectRatio: CGFloat?
        public var preferredPresentationShadow: PresentationLinkTransition.Shadow

        public init(
            preferredEdgeInset: CGFloat? = nil,
            preferredCornerRadius: CGFloat? = nil,
            preferredAspectRatio: CGFloat? = 1,
            preferredPresentationShadow: PresentationLinkTransition.Shadow = .minimal
        ) {
            self.preferredEdgeInset = preferredEdgeInset
            self.preferredCornerRadius = preferredCornerRadius
            self.preferredAspectRatio = preferredAspectRatio
            self.preferredPresentationShadow = preferredPresentationShadow
        }
    }
    public var options: Options

    public init(options: Options = .init()) {
        self.options = options
    }

    public static let defaultEdgeInset: CGFloat = 4
    public static let defaultCornerRadius: CGFloat = UIScreen.main.displayCornerRadius(min: 36)
    public static let defaultAdjustedCornerRadius: CGFloat = defaultCornerRadius - defaultEdgeInset

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
    ) -> (any UIViewControllerAnimatedTransitioning)? {
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
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        guard let presentationController = dismissed.presentationController as? InteractivePresentationController else {
            return nil
        }
        let transition = CardPresentationControllerTransition(
            preferredEdgeInset: options.preferredEdgeInset,
            preferredCornerRadius: options.preferredCornerRadius,
            isPresenting: false,
            animation: context.transaction.animation
        )
        transition.wantsInteractiveStart = presentationController.wantsInteractiveTransition
        presentationController.transition(with: transition)
        return transition
    }
}

/// A presentation controller that presents the view in a card anchored at the bottom of the screen
@available(iOS 14.0, *)
open class CardPresentationController: InteractivePresentationController {

    public var preferredEdgeInset: CGFloat? {
        didSet {
            guard oldValue != preferredEdgeInset else { return }
            cornerRadiusDidChange()
            containerView?.setNeedsLayout()
        }
    }

    public var preferredAspectRatio: CGFloat? {
        didSet {
            guard oldValue != preferredAspectRatio else { return }
            containerView?.setNeedsLayout()
        }
    }

    public var preferredCornerRadius: CGFloat? {
        didSet {
            guard oldValue != preferredCornerRadius else { return }
            cornerRadiusDidChange()
        }
    }

    open override var frameOfPresentedViewInContainerView: CGRect {
        var frame = super.frameOfPresentedViewInContainerView
        guard let presentedView else { return frame }
        if traitCollection.horizontalSizeClass == .regular {
            let width = min(frame.width, 430)
            let height = min(frame.height, 430)
            frame = CGRect(
                x: frame.midX - width / 2,
                y: frame.maxY - height,
                width: height,
                height: width
            )
        }
        let isCompact = traitCollection.verticalSizeClass == .compact
        let width = isCompact ? frame.height : frame.width
        let height: CGFloat = {
            let presentedViewAdditionalSafeAreaInsets = presentedViewController.additionalSafeAreaInsets
            if let preferredAspectRatio {
                let insets = presentedView.safeAreaInsets == .zero ? presentedViewAdditionalSafeAreaInsets : presentedView.safeAreaInsets
                let dx = containerView?.safeAreaInsets.bottom == 0 ? 0 : insets.top - min(insets.bottom, (containerView?.safeAreaInsets.bottom ?? 0) - edgeInset)
                return (preferredAspectRatio * (width - dx)).rounded(scale: containerView?.window?.screen.scale ?? 1)
            }
            let fittingWidth = width - (presentedView.safeAreaInsets == .zero ? presentedViewAdditionalSafeAreaInsets.left + presentedViewAdditionalSafeAreaInsets.right : 0) - (2 * edgeInset)
            var sizeThatFits = CGSize(
                width: fittingWidth,
                height: presentedView.idealHeight(for: fittingWidth)
            )
            if sizeThatFits.height <= 0 {
                sizeThatFits.height = width
            }
            sizeThatFits.height += (2 * edgeInset)
            if presentedView.safeAreaInsets == .zero {
                sizeThatFits.height += (presentedViewAdditionalSafeAreaInsets.top + presentedViewAdditionalSafeAreaInsets.bottom)
            }
            return min(frame.height, sizeThatFits.height)
        }()
        frame = CGRect(
            x: frame.origin.x + (frame.width - width) / 2,
            y: frame.origin.y + (frame.height - height),
            width: width,
            height: height
        )

        var keyboardOverlap: CGFloat = 0
        if shouldAutomaticallyAdjustFrameForKeyboard {
            keyboardOverlap = keyboardOverlapInContainerView(
                of: frame,
                keyboardHeight: keyboardHeight
            )
        }

        frame.origin.y -= keyboardOverlap
        if presentedView.safeAreaInsets == .zero {
            if keyboardOverlap == 0 {
                let bottomSafeArea = max(0, (containerView?.safeAreaInsets.bottom ?? 0) - edgeInset)
                frame.size.height += bottomSafeArea
                frame.origin.y -= bottomSafeArea
            }
        }

        if frame.origin.y < 0 {
            frame.size.height += frame.origin.y
            frame.origin.y = 0
        }
        frame = frame.inset(
            by: UIEdgeInsets(
                top: edgeInset,
                left: edgeInset,
                bottom: edgeInset,
                right: edgeInset
            )
        )
        return frame
    }

    private var edgeInset: CGFloat {
        preferredEdgeInset ?? CardPresentationLinkTransition.defaultEdgeInset
    }

    private var cornerRadius: CGFloat {
        preferredCornerRadius ?? (CardPresentationLinkTransition.defaultCornerRadius - edgeInset)
    }

    public init(
        preferredEdgeInset: CGFloat? = nil,
        preferredCornerRadius: CGFloat? = nil,
        preferredAspectRatio: CGFloat? = 1,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.preferredEdgeInset = preferredEdgeInset
        self.preferredCornerRadius = preferredCornerRadius
        self.preferredAspectRatio = preferredAspectRatio
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
        shouldAutomaticallyAdjustFrameForKeyboard = true
        dimmingView.isHidden = false
    }

    open override func dismissalTransitionShouldBegin(
        translation: CGPoint,
        delta: CGPoint,
        velocity: CGPoint
    ) -> Bool {
        if wantsInteractiveDismissal {
            let percentage = translation.y / presentedViewController.view.frame.height
            let magnitude = sqrt(pow(velocity.y, 2) + pow(velocity.x, 2))
            return (percentage >= 0.5 && magnitude > 0) || (magnitude >= 1000 && velocity.y > 0)
        } else {
            return super.dismissalTransitionShouldBegin(
                translation: translation,
                delta: delta,
                velocity: velocity
            )
        }
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        presentedViewController.view.layer.cornerCurve = .continuous
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            presentedViewController.view.layer.cornerRadius = cornerRadius
        }
    }

    open override func presentedViewAdditionalSafeAreaInsets() -> UIEdgeInsets {
        var edgeInsets = super.presentedViewAdditionalSafeAreaInsets()
        let safeAreaInsets = containerView?.safeAreaInsets ?? .zero
        let inset = (cornerRadius / 2).rounded(scale: containerView?.window?.screen.scale ?? 1)
        edgeInsets.top = max(edgeInsets.top, inset)
        edgeInsets.left = max(edgeInsets.left, inset)
        edgeInsets.right = max(edgeInsets.right, inset)
        edgeInsets.bottom = max(0, min(safeAreaInsets.bottom - edgeInset, edgeInsets.bottom))
        if keyboardHeight > 0 {
            edgeInsets.bottom = max(edgeInsets.bottom, inset)
        } else {
            edgeInsets.bottom += max(0, inset - safeAreaInsets.bottom)
        }
        return edgeInsets
    }

    private func cornerRadiusDidChange() {
        presentedViewController.additionalSafeAreaInsets = presentedViewAdditionalSafeAreaInsets()
    }
}

/// An interactive transition built for the ``CardPresentationController``.
///
/// ```
/// func animationController(
///     forDismissed dismissed: UIViewController
/// ) -> UIViewControllerAnimatedTransitioning? {
///     guard let presentationController = dismissed.presentationController as? CardPresentationController else {
///         return nil
///     }
///     let transition = CardPresentationControllerTransition(...)
///     transition.wantsInteractiveStart = presentationController.wantsInteractiveTransition
///     presentationController.transition(with: transition)
///     return transition
/// }
/// ```
///
@available(iOS 14.0, *)
open class CardPresentationControllerTransition: PresentationControllerTransition {

    public let preferredEdgeInset: CGFloat?
    public let preferredCornerRadius: CGFloat?

    public init(
        preferredEdgeInset: CGFloat? = nil,
        preferredCornerRadius: CGFloat? = nil,
        isPresenting: Bool,
        animation: Animation?
    ) {
        self.preferredEdgeInset = preferredEdgeInset
        self.preferredCornerRadius = preferredCornerRadius
        super.init(isPresenting: isPresenting, animation: animation)
    }

    open override func configureTransitionAnimator(
        using transitionContext: any UIViewControllerContextTransitioning,
        animator: UIViewPropertyAnimator
    ) {
        if let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from) {
            let edgeInset = preferredEdgeInset ?? CardPresentationLinkTransition.defaultEdgeInset
            let cornerRadius = preferredCornerRadius ?? (CardPresentationLinkTransition.defaultCornerRadius - edgeInset)
            presented.view.layer.cornerRadius = cornerRadius
        }
        return super.configureTransitionAnimator(using: transitionContext, animator: animator)
    }
}

#endif
