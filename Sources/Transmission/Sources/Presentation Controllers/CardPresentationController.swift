//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

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
        let isCompact = traitCollection.verticalSizeClass == .compact
        let width = isCompact ? frame.height : frame.width
        let fittingSize = CGSize(
            width: width,
            height: UIView.layoutFittingCompressedSize.height
        )
        var sizeThatFits = CGRect(
            origin: .zero,
            size: presentedView.systemLayoutSizeFitting(
                fittingSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .defaultLow
            )
        )
        .inset(by: presentedView.safeAreaInsets)
        if sizeThatFits.height <= 0 {
            sizeThatFits.size.height = width
        }
        let preferredHeightValue = preferredAspectRatio.map { $0 * (isCompact ? frame.height : frame.width) }
        let height = isCompact
            ? min(frame.height, preferredHeightValue ?? (sizeThatFits.height))
            : min(frame.height, max(sizeThatFits.height, preferredHeightValue ?? 0))
        frame = CGRect(
            x: frame.origin.x + (frame.width - width) / 2,
            y: frame.origin.y + (frame.height - height),
            width: width,
            height: height
        )
        if shouldAutomaticallyAdjustFrameForKeyboard {
            let keyboardOverlap = keyboardOverlapInContainerView(
                of: frame,
                keyboardHeight: keyboardHeight
            )
            frame.origin.y -= keyboardOverlap
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
        preferredEdgeInset ?? 4
    }

    private var cornerRadius: CGFloat {
        preferredCornerRadius ?? max(12, UIScreen.main.displayCornerRadius - edgeInset)
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
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        presentedViewController.view.layer.cornerCurve = .continuous
        cornerRadiusDidChange()
        dimmingView.isHidden = false
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            cornerRadiusDidChange()
        }
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            presentedViewController.view.layer.cornerRadius = 0
        }
    }

    open override func transitionAlongsidePresentation(isPresented: Bool) {
        super.transitionAlongsidePresentation(isPresented: isPresented)
        cornerRadiusDidChange()
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

    open override func presentedViewAdditionalSafeAreaInsets() -> UIEdgeInsets {
        var edgeInsets = super.presentedViewAdditionalSafeAreaInsets()
        let safeAreaInsets = containerView?.safeAreaInsets ?? .zero
        edgeInsets.bottom = max(0, min(safeAreaInsets.bottom - edgeInset, edgeInsets.bottom))
        return edgeInsets
    }

    private func cornerRadiusDidChange() {
        presentedViewController.view.layer.cornerRadius = cornerRadius
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
///     let transition = CardPresentationControllerTransition(
///         isPresenting: false,
///         animation: animation
///     )
///     transition.wantsInteractiveStart = options.options.isInteractive && presentationController.wantsInteractiveTransition
///     presentationController.transition(with: transition)
///     return transition
/// }
/// ```
///
@available(iOS 14.0, *)
open class CardPresentationControllerTransition: PresentationControllerTransition {

}

#endif
