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

    public var preferredPlacement: PreferredPresentationPlacement? {
        didSet {
            guard oldValue != preferredPlacement else { return }
            containerView?.setNeedsLayout()
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

    public weak var sourceView: UIView? {
        didSet {
            guard oldValue != sourceView, preferredPlacement == .sourceView else { return }
            containerView?.setNeedsLayout()
        }
    }

    open override var frameOfPresentedViewInContainerView: CGRect {
        var frame = super.frameOfPresentedViewInContainerView
        let scale = traitCollection.displayScale
        let cornerRadius = cornerRadius
        let edgeInset = edgeInset
        let availableWidth = {
            if traitCollection.verticalSizeClass == .compact {
                return frame.height
            }
            if traitCollection.horizontalSizeClass == .regular {
                #if XCODE_27_1
                if #available(iOS 27.1, *), let containerView, traitCollection.verticalBarEdge != .unspecified, containerView.bounds.width > containerView.bounds.height {
                    return (containerView.bounds.inset(by: containerView.safeAreaInsets).width / 2).rounded(scale: scale)
                }
                #endif
                return min(frame.width, 440)
            }
            return frame.width
        }()
        let height: CGFloat = {
            var fittingWidth = availableWidth - (2 * edgeInset)
            if let preferredAspectRatio {
                if let containerView, traitCollection.verticalSizeClass != .compact {
                    fittingWidth -= max(0, containerView.safeAreaInsets.left - edgeInset)
                    fittingWidth -= max(0, containerView.safeAreaInsets.right - edgeInset)
                }
                var height = (preferredAspectRatio * fittingWidth).rounded(scale: scale) + 2 * edgeInset
                let inset = max(0, (containerView?.safeAreaInsets.bottom ?? 0) - cornerRadius / 2 - edgeInset)
                if inset >= 1 {
                    height += inset
                }
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
                sizeThatFits.height = availableWidth
            }
            sizeThatFits.height += (2 * edgeInset)
            if presentedViewController.view.safeAreaInsets == .zero, presentedViewController.isBeingPresented, preferredSafeAreaInsets != .zero {
                if !isKeyboardSessionActive {
                    sizeThatFits.height += max((containerView?.safeAreaInsets.bottom ?? 0) - edgeInset, 0)
                }
                sizeThatFits.height += presentedViewController.additionalSafeAreaInsets.top
                sizeThatFits.height += presentedViewController.additionalSafeAreaInsets.bottom
            }
            return min(frame.height, sizeThatFits.height).rounded(scale: scale)
        }()
        if traitCollection.horizontalSizeClass == .regular {
            var width = availableWidth
            let height = max(height, width * (preferredAspectRatio ?? 0)).rounded(scale: scale)
            let y = frame.maxY - height
            var x = (frame.midX - availableWidth / 2).rounded(scale: scale)
            var placement = preferredPlacement ?? .center
            let isLeftToRight = presentedViewController.view.effectiveUserInterfaceLayoutDirection == .leftToRight
            if placement == .sourceView, let sourceView, let containerView {
                let midX = containerView.convert(sourceView.bounds, from: sourceView).midX
                if midX < containerView.bounds.width / 3 {
                    placement = isLeftToRight ? .leading : .trailing
                } else if midX > (containerView.bounds.width * 2 / 3) {
                    placement = isLeftToRight ? .trailing : .leading
                }
            }
            #if XCODE_27_1
            if #available(iOS 27.1, *), placement == .center || placement == .sourceView, let containerView, !containerView.reservedRegions(kind: .division).isEmpty {
                switch traitCollection.verticalBarEdge {
                case .leading:
                    placement = .trailing
                case .trailing:
                    placement = .leading
                case .unspecified:
                    break
                @unknown default:
                    break
                }
            }
            #endif
            switch (placement, isLeftToRight) {
            case (.sourceView, _), (.center, _):
                break
            case (.leading, true), (.trailing, false):
                if let preferredAspectRatio {
                    width = (height * preferredAspectRatio).rounded(scale: scale) + max(0, (containerView?.safeAreaInsets.left ?? 0) - edgeInset)
                }
                x = frame.minX
            case (.trailing, true), (.leading, false):
                if let preferredAspectRatio {
                    width = (height * preferredAspectRatio).rounded(scale: scale) + max(0, (containerView?.safeAreaInsets.right ?? 0) - edgeInset)
                }
                x = frame.maxX - width
            }
            frame = CGRect(
                x: x,
                y: y,
                width: width,
                height: height
            )
        } else {
            frame = CGRect(
                x: frame.origin.x + ((frame.width - availableWidth) / 2).rounded(scale: scale),
                y: frame.origin.y + (frame.height - height),
                width: availableWidth,
                height: height
            )
        }
        let keyboardOverlap = keyboardOverlapInContainerView(
            of: frame,
            keyboardHeight: keyboardHeight
        )
        frame.origin.y -= max(keyboardOverlap, keyboardOffset)
        let minY = insetSafeAreaByCornerRadius ? (containerView?.safeAreaInsets.top ?? 0) : 0
        if frame.origin.y < minY {
            frame.size.height += (frame.origin.y - minY)
            frame.origin.y = minY
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
        preferredEdgeInset ?? Self.defaultEdgeInset
    }

    open class var defaultEdgeInset: CGFloat {
        if #available(iOS 26.0, *) {
            return 8
        }
        return 4
    }

    private var cornerRadius: CGFloat {
        let cornerRadius = preferredCornerRadius?.cornerRadius(in: presentedView?.window) ?? max(0, displayCornerRadius - edgeInset)
        return cornerRadius
    }

    private var displayCornerRadius: CGFloat {
        CornerRadiusOptions.RoundedRectangle.screen(prefersContainerConcentric: false).cornerRadius(in: presentedView?.window) ?? 0
    }

    private func needsCustomCornerRadiusPath(cornerRadius: CGFloat) -> Bool {
        guard cornerRadius > 0, !isKeyboardSessionActive else { return false }
        let inset = cornerRadius + edgeInset
        guard inset < (containerView?.safeAreaInsets.bottom ?? 0) || !insetSafeAreaByCornerRadius else { return false }
        return inset < displayCornerRadius
    }

    private var customCornerRadiusPath: CGPath? {
        guard let bounds = presentedView?.bounds, bounds != .zero else { return nil }
        let cornerRadius = cornerRadius
        guard needsCustomCornerRadiusPath(cornerRadius: cornerRadius) else { return nil }
        return .roundedRect(
            bounds: bounds,
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

    public override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
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
        setCornerRadius()
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        setCornerRadius()
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        setCornerRadius()
    }

    open override func presentedViewAdditionalSafeAreaInsets() -> UIEdgeInsets {
        let additionalSafeAreaInsets = super.presentedViewAdditionalSafeAreaInsets()
        let safeAreaInsets = containerView?.safeAreaInsets ?? .zero
        let cornerRadius = cornerRadius
        let inset = insetSafeAreaByCornerRadius ? (cornerRadius / 2).rounded() : 0
        var edgeInsets = additionalSafeAreaInsets
        edgeInsets.top = max(edgeInsets.top, inset)
        edgeInsets.left = max(edgeInsets.left, inset)
        edgeInsets.right = max(edgeInsets.right, inset)
        if isKeyboardSessionActive {
            edgeInsets.bottom = max(edgeInsets.bottom, inset)
        } else {
            let bottomSafeArea = (safeAreaInsets.bottom - additionalSafeAreaInsets.bottom) - edgeInset
            edgeInsets.bottom = min(max(safeAreaInsets.bottom - edgeInset, inset), max(additionalSafeAreaInsets.bottom, inset - max(0, bottomSafeArea)))
        }
        return edgeInsets
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let didChangeSizeClass =  previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass
            || previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass
        if #available(iOS 26.0, *), didChangeSizeClass {
            setCornerRadius()
        }
    }

    private func cornerRadiusDidChange() {
        updatePresentedViewAdditionalSafeAreaInsets()
        setCornerRadius()
    }

    private func setCornerRadius(force: Bool = false) {
        guard !presentedViewController.isBeingDismissed else { return }
        guard !presentedViewController.isBeingPresented || presentedViewController.view.layer.cornerRadius == 0 || force else { return }
        var didApplyCornerConfiguration = false
        let cornerRadius = cornerRadius
        #if XCODE_26
        if #available(iOS 26.0, *) {
            let prefersContainerConcentric = traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass != .compact
            let cornerRadius = preferredCornerRadius ?? .unevenRounded(
                topLeading: .fixed(cornerRadius),
                bottomLeading: .screen(prefersContainerConcentric: prefersContainerConcentric),
                bottomTrailing: .screen(prefersContainerConcentric: prefersContainerConcentric),
                topTrailing: .fixed(cornerRadius),
                style: .circular
            )
            cornerRadius.setCornerRadius(to: presentedViewController.view, prefersEffectiveMinimium: true)
            didApplyCornerConfiguration = true
        }
        #endif
        if !didApplyCornerConfiguration {
            let layoutDirectionIsLeftToRight = presentedViewController.view.effectiveUserInterfaceLayoutDirection == .leftToRight
            if let maskPath = customCornerRadiusPath {
                if cornerRadiusMask == nil {
                    let shapeLayer = CAShapeLayer()
                    self.cornerRadiusMask = shapeLayer
                }
                cornerRadiusMask?.path = maskPath
                cornerRadiusMask?.cornerCurve = preferredCornerRadius?.style.toCoreAnimation() ?? .circular
                cornerRadiusMask?.maskedCorners = (preferredCornerRadius?.cornerRadii.mask ?? .all).intersection([.topLeading, .topTrailing]).toCoreAnimation(layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight)
                let isCompact = traitCollection.verticalSizeClass == .compact
                let cornerRadius = isCompact ? cornerRadius : displayCornerRadius - edgeInset
                presentedViewController.view.layer.cornerRadius = cornerRadius
                presentedViewController.view.layer.cornerCurve = cornerRadius == displayCornerRadius ? .circular : .continuous
                presentedViewController.view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else {
                if cornerRadiusMask != nil {
                    cornerRadiusMask = nil
                }
                presentedViewController.view.layer.cornerRadius = cornerRadius
                presentedViewController.view.layer.cornerCurve = cornerRadius > 0 && (cornerRadius + edgeInset) == displayCornerRadius ? .circular : (preferredCornerRadius?.style.toCoreAnimation() ?? .continuous)
                presentedViewController.view.layer.maskedCorners = (preferredCornerRadius?.cornerRadii.mask ?? .all).toCoreAnimation(layoutDirectionIsLeftToRight: layoutDirectionIsLeftToRight)
            }
        }
    }
}

/// An interactive transition built for the ``CardPresentationController``.
@available(iOS 14.0, *)
open class CardPresentationControllerTransition: PresentationControllerTransition {

}

#endif
