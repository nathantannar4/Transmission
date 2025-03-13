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
        let keyboardOverlap = keyboardOverlapInContainerView(
            of: frame,
            keyboardHeight: keyboardHeight
        )
        let width = isCompact ? frame.height : frame.width
        let fittingSize = CGSize(
            width: width,
            height: UIView.layoutFittingCompressedSize.height
        )
        let sizeThatFits = presentedView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        )
        let height = isCompact ? frame.height - keyboardOverlap : min(frame.height, max(sizeThatFits.height - presentedView.safeAreaInsets.top - presentedView.safeAreaInsets.bottom, frame.width))
        frame = CGRect(
            x: frame.origin.x + (frame.width - width) / 2,
            y: frame.origin.y + (frame.height - height),
            width: width,
            height: height
        )
        if !isTransitioningSize {
            frame.origin.y -= keyboardOverlap
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
        preferredEdgeInset: CGFloat?,
        preferredCornerRadius: CGFloat?,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.preferredEdgeInset = preferredEdgeInset
        self.preferredCornerRadius = preferredCornerRadius
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        cornerRadiusDidChange()
        dimmingView.isHidden = false
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            presentedViewController.view.layer.cornerRadius = 0
        }
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
        let cornerRadius = cornerRadius
        presentedViewController.view.layer.masksToBounds = cornerRadius > 0
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
