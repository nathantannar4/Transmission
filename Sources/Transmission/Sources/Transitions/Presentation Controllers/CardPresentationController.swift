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

    public var insetSafeAreaByCornerRadius: Bool = true {
        didSet {
            guard insetSafeAreaByCornerRadius != oldValue else { return }
            cornerRadiusDidChange()
            containerView?.setNeedsLayout()
        }
    }

    public var preferredSafeAreaInsets: UIEdgeInsets? {
        didSet {
            guard oldValue != preferredSafeAreaInsets else { return }
            containerView?.setNeedsLayout()
        }
    }

    open override var frameOfPresentedViewInContainerView: CGRect {
        var frame = super.frameOfPresentedViewInContainerView
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
            var fittingWidth = width - (2 * edgeInset)
            let inset = (isKeyboardSessionActive ? cornerRadius / 2 : max((containerView?.safeAreaInsets.bottom ?? 0) - cornerRadius / 2, 0))
            if let preferredAspectRatio {
                let height = (preferredAspectRatio * fittingWidth).rounded(scale: containerView?.window?.screen.scale ?? 1) + inset + edgeInset
                return height
            }
            if presentedViewController.view.safeAreaInsets == .zero, presentedViewController.isBeingPresented {
                fittingWidth -= presentedViewController.additionalSafeAreaInsets.left
                fittingWidth -= presentedViewController.additionalSafeAreaInsets.right
            }
            var sizeThatFits = CGSize(
                width: fittingWidth,
                height: presentedViewController.view.idealHeight(for: fittingWidth)
            )
            if sizeThatFits.height <= 0 {
                sizeThatFits.height = width
            }
            sizeThatFits.height += (2 * edgeInset)
            if presentedViewController.view.safeAreaInsets == .zero, presentedViewController.isBeingPresented {
                sizeThatFits.height += max((containerView?.safeAreaInsets.bottom ?? 0) - edgeInset, 0)
                sizeThatFits.height += presentedViewController.additionalSafeAreaInsets.top
                sizeThatFits.height += presentedViewController.additionalSafeAreaInsets.bottom
            }
            return min(frame.height, sizeThatFits.height).rounded(scale: containerView?.window?.screen.scale ?? 1)
        }()
        frame = CGRect(
            x: frame.origin.x + (frame.width - width) / 2,
            y: frame.origin.y + (frame.height - height),
            width: width,
            height: height
        )

        let keyboardOverlap = keyboardOverlapInContainerView(
            of: frame,
            keyboardHeight: keyboardHeight
        )
        frame.origin.y -= keyboardOverlap
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
        guard cornerRadius > 0, !isKeyboardSessionActive else { return false }
        let inset = cornerRadius + edgeInset
        guard inset < (containerView?.safeAreaInsets.bottom ?? 0) || !insetSafeAreaByCornerRadius else { return false }
        return inset < UIScreen.main.displayCornerRadius()
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
        insetSafeAreaByCornerRadius: Bool = true,
        preferredAspectRatio: CGFloat? = 1,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.preferredEdgeInset = preferredEdgeInset
        self.preferredCornerRadius = preferredCornerRadius
        self.insetSafeAreaByCornerRadius = insetSafeAreaByCornerRadius
        self.preferredAspectRatio = preferredAspectRatio
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
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
        setCornerRadius()
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            setCornerRadius()
        }
    }

    open override func presentedViewAdditionalSafeAreaInsets() -> UIEdgeInsets {
        let additionalSafeAreaInsets = super.presentedViewAdditionalSafeAreaInsets()
        let safeAreaInsets = containerView?.safeAreaInsets ?? .zero
        let inset = insetSafeAreaByCornerRadius ? (cornerRadius / 2).rounded(scale: containerView?.window?.screen.scale ?? 1) : 0
        var edgeInsets = additionalSafeAreaInsets
        edgeInsets.top = max(edgeInsets.top, inset)
        edgeInsets.left = max(edgeInsets.left, inset)
        edgeInsets.right = max(edgeInsets.right, inset)
        if isKeyboardSessionActive {
            edgeInsets.bottom = max(edgeInsets.bottom, inset)
        } else {
            let bottomSafeArea = (safeAreaInsets.bottom - additionalSafeAreaInsets.bottom) - edgeInset
            edgeInsets.bottom = inset - max(0, bottomSafeArea)
        }
        return edgeInsets
    }

    open override func layoutPresentedView(frame: CGRect) {
        super.layoutPresentedView(frame: frame)
        if let cornerRadiusMask {
            cornerRadiusMask.path = customCornerRadiusPath
        }
    }

    open override func transitionAlongsidePresentation(progress: CGFloat) {
        super.transitionAlongsidePresentation(progress: progress)

        if progress == 1, needsCustomCornerRadiusPath {
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
        let cornerRadius = cornerRadius
        var didApplyCornerConfiguration = false
        #if canImport(FoundationModels) // Xcode 26
        if #available(iOS 26.0, *) {
            let mask = preferredCornerRadius?.mask ?? .all
            let corner = isKeyboardSessionActive ? UICornerRadius.fixed(cornerRadius) : .containerConcentric(minimum: cornerRadius)
            presentedViewController.view.cornerConfiguration = UICornerConfiguration.corners(
                topLeftRadius: mask.contains(.layerMinXMinYCorner) ? corner : .fixed(0),
                topRightRadius: mask.contains(.layerMaxXMinYCorner) ? corner : .fixed(0),
                bottomLeftRadius: mask.contains(.layerMinXMaxYCorner) ? corner : .fixed(0),
                bottomRightRadius: mask.contains(.layerMaxXMaxYCorner) ? corner : .fixed(0)
            )
            didApplyCornerConfiguration = true
        }
        #endif
        if !didApplyCornerConfiguration {
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
