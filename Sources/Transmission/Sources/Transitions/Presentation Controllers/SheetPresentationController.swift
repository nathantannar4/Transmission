//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI
import Engine

#if targetEnvironment(macCatalyst)
@available(iOS 15.0, *)
public typealias SheetPresentationController = MacSheetPresentationController

@available(iOS 15.0, *)
open class MacSheetTransition: SlidePresentationControllerTransition {

    public init(
        isPresenting: Bool,
        animation: Animation?
    ) {
        super.init(
            edge: .bottom,
            isPresenting: isPresenting,
            animation: animation
        )
    }
}

@available(iOS 15.0, *)
open class MacSheetPresentationController: SlidePresentationController {

    public var detent: PresentationLinkTransition.SheetTransitionOptions.Detent = .large {
        didSet {
            dimmingView.isHidden = largestUndimmedDetentIdentifier == detent.identifier
        }
    }

    var selected: Binding<PresentationLinkTransition.SheetTransitionOptions.Detent.Identifier?>?
    var largestUndimmedDetentIdentifier: PresentationLinkTransition.SheetTransitionOptions.Detent.Identifier?

    private var prevPresentationController: MacSheetPresentationController? {
        presentingViewController._activePresentationController as? MacSheetPresentationController
    }

    private var depth = 0 {
        didSet {
            layoutPresentedView(frame: frameOfPresentedViewInContainerView)
            dimmingView.alpha = depth > 0 ? 0 : 1
        }
    }

    private func push() {
        prevPresentationController?.depth += 1
        prevPresentationController?.prevPresentationController?.depth += 1
    }

    private func pop() {
        prevPresentationController?.depth -= 1
        prevPresentationController?.prevPresentationController?.depth -= 1
    }

    open override var frameOfPresentedViewInContainerView: CGRect {
        let frame = super.frameOfPresentedViewInContainerView.inset(by: containerView?.safeAreaInsets ?? .zero)
        let isPinnedToEdges = frame.size.height > (1.5 * frame.size.width)
        let targetRect: CGRect = {
            if isPinnedToEdges {
                let height = (frame.size.height * 0.95).rounded(.up)
                return CGRect(
                    x: frame.origin.x,
                    y: frame.origin.y + (frame.size.height - height),
                    width: frame.size.width,
                    height: height
                )
            } else {
                let width = (frame.size.width * 0.85).rounded(.up)
                let height = (frame.size.height * 0.85).rounded(.up)
                return CGRect(
                    x: frame.origin.x + (frame.size.width - width) / 2,
                    y: frame.origin.y + (frame.size.height - height) / 2,
                    width: width,
                    height: height
                )
            }
        }()
        switch detent.identifier {
        case .large:
            return targetRect

        case .medium:
            let height = (frame.size.height / 2).rounded(.up)
            return CGRect(
                x: targetRect.origin.x,
                y: isPinnedToEdges ? targetRect.maxY - height : targetRect.origin.y + (targetRect.size.height - height) / 2,
                width: targetRect.width,
                height: height
            )

        case .ideal:
            let targetHeight = presentedViewController.view.idealHeight(for: targetRect.width)

            return CGRect(
                x: targetRect.origin.x,
                y: isPinnedToEdges ? targetRect.maxY - targetHeight : targetRect.origin.y + (targetRect.size.height - targetHeight) / 2,
                width: targetRect.width,
                height: targetHeight
            )

        default:
            let height: CGFloat
            if let constant = detent.height {
                height = min(constant, targetRect.size.height)
            } else if let resolution = detent.resolution {
                height = resolution(
                    .init(
                        containerTraitCollection: traitCollection,
                        maximumDetentValue: targetRect.size.height,
                        idealDetentValue: { [weak presentedViewController] in
                            guard let presentedViewController else { return 0 }
                            let targetHeight = presentedViewController.view.idealHeight(for: targetRect.width)
                            return targetHeight
                        }
                    )
                ) ?? targetRect.size.height
            } else {
                return targetRect
            }
            return CGRect(
                x: targetRect.origin.x,
                y: isPinnedToEdges ? targetRect.maxY - height : targetRect.origin.y + (targetRect.size.height - height) / 2,
                width: targetRect.width,
                height: height
            )
        }
    }

    public init(
        preferredCornerRadius: CornerRadiusOptions.RoundedRectangle?,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        let cornerRadius = preferredCornerRadius ?? .rounded(cornerRadius: 12)
        super.init(
            edge: .bottom,
            prefersScaleEffect: false,
            preferredFromCornerRadius: cornerRadius,
            preferredToCornerRadius: cornerRadius,
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
        presentedViewShadow = .minimal
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        selected?.wrappedValue = detent.identifier

        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { [unowned self] _ in
                self.push()
            }, completion: { [unowned self] ctx in
                if ctx.isCancelled {
                    self.pop()
                }
            })
        }
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        if !completed {
            selected?.wrappedValue = nil
        }
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { [unowned self] _ in
                self.pop()
            }, completion: { [unowned self] ctx in
                if ctx.isCancelled {
                    self.push()
                }
            })
        }
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            selected?.wrappedValue = nil
        }
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        if let presentedView = presentedView {
            let isPinnedToEdges = presentedView.frame.size.height > (1.5 * presentedView.frame.size.width)
            presentedView.layer.maskedCorners = isPinnedToEdges
                ? [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                : [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
    }

    open override func layoutPresentedView(frame: CGRect) {
        presentedView?.transform = .identity
        super.layoutPresentedView(frame: frame)
        if depth > 0 {
            let scale: CGFloat = pow(0.92, CGFloat(depth))
            presentedView?.transform = CGAffineTransform(scaleX: scale, y: scale)
                .translatedBy(x: 0, y: (frame.height * -0.08))
        } else {
            presentedView?.transform = .identity
        }
    }
}
#else
@available(iOS 15.0, *)
open class SheetPresentationController: UISheetPresentationController {

    public var preferredCornerRadiusOptions: CornerRadiusOptions.RoundedRectangle? {
        didSet {
            guard preferredCornerRadiusOptions != oldValue else { return }
            updateCornerRadius()
        }
    }

    public var preferredBackgroundColor: UIColor? {
        didSet {
            guard preferredBackgroundColor != oldValue else { return }
            updateBackgroundColor()
        }
    }

    public var preferredPresentationSafeAreaInsets: UIEdgeInsets? {
        didSet {
            guard preferredPresentationSafeAreaInsets != oldValue else { return }
            updatePresentedViewInset()
        }
    }

    private var dropShadowView: UIView? {
        if let lastSubview = containerView?.subviews.last, lastSubview.isDropShadowView {
            return lastSubview
        }
        return nil
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

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        updateBackgroundColor()
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        if completed {
            presentedViewController.fixSwiftUIHitTesting()
        } else {
            delegate?.presentationControllerDidDismiss?(self)
        }
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        updateBackgroundColor()
        delegate?.presentationControllerWillDismiss?(self)
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            delegate?.presentationControllerDidDismiss?(self)
        } else {
            delegate?.presentationControllerDidAttemptToDismiss?(self)
            presentedViewController.fixSwiftUIHitTesting()
        }
    }

    open override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        // Fix presentation animation
        if #available(iOS 26.0, *),
            presentedViewController.isBeingPresented,
            let presentedView,
            presentedView.transform != .identity,
            presentedView.transform.tx == 0
        {
            let dx = (1 - presentedView.transform.a) * presentedView.bounds.width / 2
            presentedView.transform = presentedView.transform.translatedBy(x: dx, y: 0)
        }
    }

    private func updateCornerRadius() {
        preferredCornerRadius = preferredCornerRadiusOptions?.cornerRadius
    }

    private func updateBackgroundColor() {
        if let preferredBackgroundColor {
            dropShadowView?.layer.shadowColor = preferredBackgroundColor.cgColor
        }
        if #available(iOS 26.0, *) {
            let hasTranslucentBackground = preferredBackgroundColor?.isTranslucent == true
            // _setLargeBackground:
            let aSelectorSetLargeBackground = NSSelectorFromBase64EncodedString("X3NldExhcmdlQmFja2dyb3VuZDo=")
            if responds(to: aSelectorSetLargeBackground) {
                perform(aSelectorSetLargeBackground, with: hasTranslucentBackground ? UIColor.clear : nil)
            }
            // _setNonLargeBackground:
            let aSelectorSetNonLargeBackground = NSSelectorFromBase64EncodedString("X3NldE5vbkxhcmdlQmFja2dyb3VuZDo=")
            if responds(to: aSelectorSetNonLargeBackground) {
                perform(aSelectorSetNonLargeBackground, with: hasTranslucentBackground ? UIColor.clear : nil)
            }
        }
        updatePresentedViewInset()
    }

    private func updatePresentedViewInset() {
        if #available(iOS 26.0, *) {
            disableSolariumInsets = preferredPresentationSafeAreaInsets == .zero
        }
    }
}

extension UIView {

    private static let UIDropShadowView: AnyClass? = NSClassFromString("UIDropShadowView")
    var isDropShadowView: Bool {
        guard let aClass = Self.UIDropShadowView else {
            return false
        }
        return isKind(of: aClass)
    }
}
#endif

@available(iOS 15.0, *)
extension PresentationLinkTransition.SheetTransitionOptions {

    @MainActor @preconcurrency
    static func update(
        presentationController: SheetPresentationController,
        animation: Animation?,
        from oldValue: Self,
        to newValue: Self
    ) {
        let detents = newValue.detents
        #if targetEnvironment(macCatalyst)
        let hasChanges: Bool = {
            if oldValue.largestUndimmedDetentIdentifier != newValue.largestUndimmedDetentIdentifier {
                return true
            } else if let selected = newValue.selected,
                presentationController.detent.identifier != selected.wrappedValue
            {
                return true
            } else if oldValue.detents != detents {
                return true
            }
            return false
        }()
        #else
        presentationController.preferredBackgroundColor = newValue.options.preferredPresentationBackgroundUIColor
        presentationController.preferredPresentationSafeAreaInsets = newValue.options.preferredPresentationSafeAreaInsets.map {
            UIEdgeInsets(edgeInsets: $0, layoutDirection: presentationController.traitCollection.layoutDirection)
        }
        let selectedDetentIdentifier = newValue.selected?.wrappedValue?.toUIKit()
        let hasChanges: Bool = {
            if oldValue.preferredCornerRadius != newValue.preferredCornerRadius {
                return true
            } else if oldValue.largestUndimmedDetentIdentifier != newValue.largestUndimmedDetentIdentifier {
                return true
            } else if let selected = selectedDetentIdentifier,
                      presentationController.selectedDetentIdentifier != selected
            {
                return true
            } else if oldValue.detents != detents {
                return true
            }
            if #available(iOS 17.0, *), oldValue.prefersPageSizing != newValue.prefersPageSizing {
                return true
            }
            return false
        }()
        #endif
        if hasChanges {
            func applyConfiguration() {
                #if targetEnvironment(macCatalyst)
                presentationController.largestUndimmedDetentIdentifier = newValue.largestUndimmedDetentIdentifier
                presentationController.selected = newValue.selected
                let selected = newValue.selected?.wrappedValue
                presentationController.detent = detents.first(where: { $0.identifier == selected }) ?? detents.first ?? .large
                #else
                presentationController.detents = detents.map { $0.toUIKit(in: presentationController) }
                presentationController.largestUndimmedDetentIdentifier = newValue.largestUndimmedDetentIdentifier?.toUIKit()
                if let selected = newValue.selected {
                    presentationController.selectedDetentIdentifier = selected.wrappedValue?.toUIKit()
                }
                presentationController.preferredCornerRadiusOptions = newValue.preferredCornerRadius
                if #available(iOS 17.0, *) {
                    presentationController.prefersPageSizing = newValue.prefersPageSizing
                }
                #endif
            }
            if let animation {
                withCATransaction {
                    #if targetEnvironment(macCatalyst)
                    UIView.animate(with: animation) {
                        applyConfiguration()
                    }
                    #else
                    presentationController.animateChanges {
                        applyConfiguration()
                    }
                    #endif
                }
            } else {
                applyConfiguration()
            }
        }
    }
}

#endif
