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
            updateAdditionalSafeAreaInsets()
        }
    }

    open override var frameOfPresentedViewInContainerView: CGRect {
        var frame = super.frameOfPresentedViewInContainerView
        if keyboardHeight > 0 {
            let dy = keyboardOverlapInContainerView(
                of: frame,
                keyboardHeight: keyboardHeight
            )
            frame.size.height -= dy
        }
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
        guard cornerRadius > 0, !isKeyboardSessionActive else { return false }
        let inset = cornerRadius + edgeInset
        guard inset < (containerView?.safeAreaInsets.bottom ?? 0) || !insetSafeAreaByCornerRadius else { return false }
        return inset < UIScreen.main.displayCornerRadius()
    }

    private var customCornerRadiusPath: CGPath? {
        guard needsCustomCornerRadiusPath else { return nil }
        let bottomCornerRadius = UIScreen.main.displayCornerRadius() - edgeInset
        return .roundedRect(
            bounds: presentedView?.bounds ?? .init(origin: .zero, size: frameOfPresentedViewInContainerView.size),
            topLeft: cornerRadius,
            topRight: cornerRadius,
            bottomLeft: bottomCornerRadius,
            bottomRight: bottomCornerRadius
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
        prefersInteractiveDismissal = true
    }

    open override func dismissalTransitionShouldBegin(
        translation: CGPoint,
        delta: CGPoint,
        velocity: CGPoint
    ) -> Bool {
        if wantsInteractiveDismissal {
            let percentage = translation.y / max(presentedView?.frame.height ?? 0, 1)
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
        updateCornerRadius()
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            updateCornerRadius()
        }
    }

    open override func layoutPresentedView(frame: CGRect) {
        super.layoutPresentedView(frame: frame)
        if let cornerRadiusMask {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            cornerRadiusMask.path = customCornerRadiusPath
            CATransaction.commit()
        }
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        updateCornerRadius()
    }

    private func cornerRadiusDidChange() {
        updateCornerRadius()
    }

    private func updateCornerRadius() {
        updateAdditionalSafeAreaInsets()
        let cornerRadius = cornerRadius
        let needsCustomCornerRadiusPath = needsCustomCornerRadiusPath
        let isCompact = traitCollection.verticalSizeClass == .compact
        let bottomCornerRadius = isCompact || isKeyboardSessionActive ? cornerRadius : UIScreen.main.displayCornerRadius() - edgeInset
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if needsCustomCornerRadiusPath {
                let cornerConfiguration = UICornerConfiguration.corners(
                    topLeftRadius: .fixed(cornerRadius),
                    topRightRadius: .fixed(cornerRadius),
                    bottomLeftRadius: .containerConcentric(minimum: bottomCornerRadius),
                    bottomRightRadius: .containerConcentric(minimum: bottomCornerRadius)
                )
                if let presentedView {
                    CornerRadiusOptions.RoundedRectangle.identity.apply(to: presentedView.layer)
                }
                presentedContainerView.updateCornerConfiguration(cornerConfiguration)
            } else {
                let mask = preferredCornerRadius?.mask ?? .all
                presentedContainerView.updateCornerConfiguration(
                    UICornerConfiguration.corners(
                        topLeftRadius: .fixed(mask.contains(.layerMinXMinYCorner) ? cornerRadius : 0),
                        topRightRadius: .fixed(mask.contains(.layerMaxXMinYCorner) ? cornerRadius : 0),
                        bottomLeftRadius: .fixed(mask.contains(.layerMinXMaxYCorner) ? cornerRadius : 0),
                        bottomRightRadius: .fixed(mask.contains(.layerMaxXMaxYCorner) ? cornerRadius : 0),
                    )
                )
            }
            presentedView?.layer.cornerCurve = cornerRadius > 0 && (cornerRadius + edgeInset) == UIScreen.main.displayCornerRadius() ? .continuous : (preferredCornerRadius?.style ?? .circular)
        }
        #endif
        if #unavailable(iOS 26.0) {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if let maskPath = customCornerRadiusPath {
                presentedView?.layer.cornerRadius = bottomCornerRadius
                presentedView?.layer.cornerCurve = .continuous
                presentedView?.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                if cornerRadiusMask == nil {
                    let shapeLayer = CAShapeLayer()
                    self.cornerRadiusMask = shapeLayer
                }
                cornerRadiusMask?.path = maskPath
            } else if !needsCustomCornerRadiusPath {
                presentedView?.layer.cornerRadius = cornerRadius
                presentedView?.layer.cornerCurve = cornerRadius > 0 && (cornerRadius + edgeInset) == UIScreen.main.displayCornerRadius() ? .continuous : (preferredCornerRadius?.style ?? .circular)
                presentedView?.layer.maskedCorners = preferredCornerRadius?.mask ?? .all
                if cornerRadiusMask != nil {
                    cornerRadiusMask = nil
                }
            }
            CATransaction.commit()
        }
    }

    private func additionalSafeAreaInsets() -> UIEdgeInsets {
        let inset = insetSafeAreaByCornerRadius ? cornerRadius / 2 : 0
        let additionalSafeAreaInsets = UIEdgeInsets(
            top: inset,
            left: inset,
            bottom: isKeyboardSessionActive ? inset : max(0, (inset + edgeInset) - (containerView?.safeAreaInsets.bottom ?? 0)),
            right: inset
        )
        return additionalSafeAreaInsets
    }

    private func updateAdditionalSafeAreaInsets() {
        let additionalSafeAreaInsets = additionalSafeAreaInsets()
        if presentedViewController.additionalSafeAreaInsets != additionalSafeAreaInsets {
            presentedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets
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
            let presentedView = transitionContext.view(forKey: isPresenting ? .to : .from) ?? presented.view,
            !(presented.presentationController is CardPresentationController)
        {
            let edgeInset = preferredEdgeInset ?? CardPresentationLinkTransition.defaultEdgeInset
            let cornerRadius = preferredCornerRadius ?? .rounded(cornerRadius: (CardPresentationLinkTransition.defaultCornerRadius - edgeInset), style: .continuous)
            cornerRadius.apply(to: presentedView.layer)
        }
        return super.configureTransitionAnimator(using: transitionContext, animator: animator)
    }
}

#endif
