//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

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

    public var preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? {
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
            return min(frame.height, sizeThatFits.height).rounded(.down)
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

            if keyboardHeight > 0 {
                frame.origin.y += presentedViewController.additionalSafeAreaInsets.bottom
            }
        }

        frame.origin.y -= keyboardOverlap
        if presentedView.safeAreaInsets == .zero {
            if keyboardOverlap == 0, presentedViewController.isBeingPresented {
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
        preferredCornerRadius?.cornerRadius ?? (CardPresentationLinkTransition.defaultCornerRadius - edgeInset)
    }

    private var needsCustomCornerRadiusPath: Bool {
        edgeInset > 0 && cornerRadius > 0 && (cornerRadius + edgeInset) < UIScreen.main.displayCornerRadius()
    }

    private var customCornerRadiusPath: CGPath? {
        guard needsCustomCornerRadiusPath, let bounds = presentedView?.bounds, bounds != .zero else { return nil }
        return .roundedRect(
            bounds: presentedView?.bounds ?? .zero,
            topLeft: cornerRadius,
            topRight: cornerRadius,
            bottomLeft: 0,
            bottomRight: 0
        )
    }

    private var cornerRadiusMask: CAShapeLayer? {
        didSet {
            presentedView?.layer.mask = cornerRadiusMask
        }
    }

    public init(
        preferredEdgeInset: CGFloat? = nil,
        preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
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

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            setCornerRadius()
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
            edgeInsets.bottom = max(edgeInsets.bottom, cornerRadius)
        } else {
            edgeInsets.bottom += max(0, inset - safeAreaInsets.bottom)
        }
        return edgeInsets
    }

    open override func layoutPresentedView(frame: CGRect) {
        super.layoutPresentedView(frame: frame)
        if let cornerRadiusMask {
            cornerRadiusMask.path = customCornerRadiusPath
        }
    }

    open override func transitionAlongsidePresentation(isPresented: Bool) {
        super.transitionAlongsidePresentation(isPresented: isPresented)

        if isPresented, needsCustomCornerRadiusPath {
            setCornerRadius(force: true)
        }
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        setCornerRadius()
    }

    private func cornerRadiusDidChange() {
        let additionalSafeAreaInsets = presentedViewAdditionalSafeAreaInsets()
        if presentedViewController.additionalSafeAreaInsets != additionalSafeAreaInsets {
            presentedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets
        }
        setCornerRadius()
    }

    private func setCornerRadius(force: Bool = false) {
        guard !presentedViewController.isBeingDismissed else { return }
        guard !presentedViewController.isBeingPresented || presentedViewController.view.layer.cornerRadius == 0 || force else { return }
        if let maskPath = customCornerRadiusPath {
            if cornerRadiusMask == nil {
                let shapeLayer = CAShapeLayer()
                self.cornerRadiusMask = shapeLayer
            }
            cornerRadiusMask?.path = maskPath
            cornerRadiusMask?.cornerCurve = preferredCornerRadius?.style ?? .circular
            cornerRadiusMask?.maskedCorners = (preferredCornerRadius?.mask ?? .all).intersection([.layerMinXMinYCorner, .layerMaxXMinYCorner])
            let isCompact = traitCollection.verticalSizeClass == .compact
            if isCompact {
                presentedViewController.view.layer.cornerRadius = cornerRadius
            } else {
                presentedViewController.view.layer.cornerRadius = UIScreen.main.displayCornerRadius() - edgeInset
            }
            presentedViewController.view.layer.cornerCurve = .continuous
            presentedViewController.view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            if cornerRadiusMask != nil {
                cornerRadiusMask = nil
            }
            presentedViewController.view.layer.cornerRadius = cornerRadius
            presentedViewController.view.layer.cornerCurve = cornerRadius > 0 && (cornerRadius + edgeInset) == UIScreen.main.displayCornerRadius() ? .continuous : (preferredCornerRadius?.style ?? .circular)
            presentedViewController.view.layer.maskedCorners = preferredCornerRadius?.mask ?? .all
        }
    }
}

/// An interactive transition built for the ``CardPresentationController``.
@available(iOS 14.0, *)
open class CardPresentationControllerTransition: PresentationControllerTransition {

    public let preferredEdgeInset: CGFloat?
    public let preferredCornerRadius: CornerRadiusOptions.RoundedRectangle?

    public init(
        preferredEdgeInset: CGFloat? = nil,
        preferredCornerRadius: CornerRadiusOptions.RoundedRectangle? = nil,
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
        if let presented = transitionContext.viewController(forKey: isPresenting ? .to : .from),
            !(presented.presentationController is CardPresentationController)
        {
            let edgeInset = preferredEdgeInset ?? CardPresentationLinkTransition.defaultEdgeInset
            let cornerRadius = preferredCornerRadius ?? .rounded(cornerRadius: (CardPresentationLinkTransition.defaultCornerRadius - edgeInset), style: .continuous)
            cornerRadius.apply(to: presented.view.layer)
        }
        return super.configureTransitionAnimator(using: transitionContext, animator: animator)
    }
}

#endif
