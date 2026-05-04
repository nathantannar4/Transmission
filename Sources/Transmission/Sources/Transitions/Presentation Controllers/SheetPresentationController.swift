//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI
import Engine

#if targetEnvironment(macCatalyst)
@available(iOS 15.0, *)
open class SheetPresentationController: InteractivePresentationController {

    public var detent: SheetPresentationLinkTransition.Detent = .large {
        didSet {
            dimmingView.isHidden = largestUndimmedDetentIdentifier == detent.identifier
        }
    }

    var selected: Binding<SheetPresentationLinkTransition.Detent.Identifier?>?
    var largestUndimmedDetentIdentifier: SheetPresentationLinkTransition.Detent.Identifier? {
        didSet {
            dimmingView.isHidden = largestUndimmedDetentIdentifier == detent.identifier
        }
    }

    public var preferredCornerRadius: CornerRadiusOptions.RoundedRectangle?

    private var prevPresentationController: SheetPresentationController? {
        presentingViewController._activePresentationController as? SheetPresentationController
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
        self.preferredCornerRadius = preferredCornerRadius
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        presentedViewShadow = .minimal
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        selected?.wrappedValue = detent.identifier

        if let presentedView {
            let toCornerRadius = preferredCornerRadius ?? .screen(min: 12)
            toCornerRadius.apply(to: presentedView)
        }

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
open class SheetPresentationController: UISheetPresentationController, PercentDrivenInteractivePresentationController {

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

    @available(iOS 26.0, *)
    public var prefersSheetInset: Bool {
        get { !disableSolariumInsets }
        set { disableSolariumInsets = !newValue }
    }

    public var shouldAdjustDetentsForKeyboard: Bool {
        get { shouldAdjustDetentsToAvoidKeyboard }
        set {
            let oldValue = shouldAdjustDetentsToAvoidKeyboard
            guard newValue != oldValue else { return }
            shouldAdjustDetentsToAvoidKeyboard = newValue
            if newValue {
                unregisterKeyboardNotifications()
            } else {
                registerKeyboardNotifications()
            }
        }
    }

    /// The interactive transition driving the presentation or dismissal animation
    public weak var transition: UIPercentDrivenInteractiveTransition?

    public override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    open func attach(to transition: UIPercentDrivenInteractiveTransition) {
        transition.wantsInteractiveStart = transition.wantsInteractiveStart && isDragging
        self.transition = transition

        interactionController = transition
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        updateBackgroundColor()
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        if completed {
            presentedViewController.fixSwiftUIHitTesting()
            panGesture?.addTarget(self, action: #selector(didPan(_:)))
            if let scrollView = presentedViewController.contentScrollView(for: .bottom) {
                scrollView.panGestureRecognizer.addTarget(self, action: #selector(didPan(_:)))
            }
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

    private func updateCornerRadius() {
        preferredCornerRadius = preferredCornerRadiusOptions?.cornerRadius
    }

    private func updateBackgroundColor() {
        if let preferredBackgroundColor {
            dimmingView?.layer.shadowColor = preferredBackgroundColor.cgColor
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
    }

    @objc
    private func didPan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            let translation = gesture.translation(in: gesture.view)
            if #available(iOS 26.0, *), presentedViewController.isBeingDismissed, translation.y < 0, let interactionController, interactionController.completionSpeed < 1 {
                // Fix UIKit transition delaying ending, `completionSpeed` is
                interactionController.pause()
                interactionController.completionSpeed = 1
                interactionController.cancel()
            }
        case .ended:
            if selectedDetentIdentifier == .large {
                var shouldDismiss = gesture.velocity(in: gesture.view).y >= 4000
                if shouldDismiss, let scrollView = gesture.view as? UIScrollView {
                    shouldDismiss = scrollView.contentOffset.y <= scrollView.adjustedContentInset.top
                }
                if shouldDismiss, delegate?.presentationControllerShouldDismiss?(self) != false {
                    presentedViewController.dismiss(animated: true)
                }
            } else if !shouldAdjustDetentsForKeyboard {
                if presentedViewController.isBeingDismissed,
                   let transitionCoordinator = presentedViewController.transitionCoordinator,
                   !transitionCoordinator.isCancelled
                {
                    return
                }
                presentedViewController.fixSwiftUIHitTesting()
                withCATransaction {
                    self.animateChanges {
                        self.containerView?.layoutIfNeeded()
                    }
                }
            }
        default:
            break
        }
    }

    // MARK: - Keyboard Handling

    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(layoutContainerViewForKeyboardNotification(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(layoutContainerViewForKeyboardNotification(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc
    func _shouldDismissByDragging() -> Bool {
        if !shouldAdjustDetentsForKeyboard {
            return false
        }
        guard
            let aClass = class_getSuperclass(Self.self),
            // _shouldDismissByDragging
            let aSelector = NSSelectorFromBase64EncodedString("X3Nob3VsZERpc21pc3NCeURyYWdnaW5n"),
            let imp = class_getMethodImplementation(aClass, aSelector)
        else {
            return true
        }
        typealias Fn = @convention(c) (AnyObject, Selector) -> Bool
        let fn = unsafeBitCast(imp, to: Fn.self)
        let shouldDismiss = fn(self, aSelector)
        return shouldDismiss
    }

    @objc
    private func layoutContainerViewForKeyboardNotification(_ notification: Notification) {
        guard
            !presentedViewController.isBeingDismissed,
            presentedViewController.presentedViewController == nil,
            detents.contains(where: { $0.isDynamic }),
            let userInfo = notification.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
        else {
            return
        }
        if #available(iOS 26.0, *) {
            layoutContainerView(duration: duration, options: UIView.AnimationOptions(curve: curve))
        } else {
            withCATransaction {
                self.layoutContainerView(duration: duration, options: UIView.AnimationOptions(curve: curve))
            }
        }
    }

    private func layoutContainerView(
        duration: TimeInterval,
        options: UIView.AnimationOptions
    ) {
        guard let containerView else { return }
        UIView.transition(
            with: containerView,
            duration: duration,
            options:  [
                .beginFromCurrentState,
                .allowUserInteraction,
                options
            ]
        ) {
            if #available(iOS 16.0, *) {
                self.invalidateDetents()
            }
            self.containerView?.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.presentedViewController.fixSwiftUIHitTesting()
        }
    }
}

#endif

@available(iOS 15.0, *)
extension SheetPresentationLinkTransition.Options {

    @MainActor @preconcurrency
    static func update(
        presentationController: SheetPresentationController,
        animation: Animation?,
        from oldValue: Self,
        to newValue: Self,
        preferredBackgroundColor: UIColor?
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
        presentationController.prefersScrollingExpandsWhenScrolledToEdge = newValue.prefersScrollingExpandsWhenScrolledToEdge
        presentationController.prefersEdgeAttachedInCompactHeight = newValue.prefersEdgeAttachedInCompactHeight
        presentationController.widthFollowsPreferredContentSizeWhenEdgeAttached = newValue.widthFollowsPreferredContentSizeWhenEdgeAttached
        presentationController.shouldAdjustDetentsForKeyboard = newValue.shouldAdjustDetentsForKeyboard
        if #available(iOS 26.0, *) {
            presentationController.prefersSheetInset = newValue.prefersSheetInset
        }
        presentationController.preferredBackgroundColor = preferredBackgroundColor
        let selectedDetentIdentifier = newValue.selected?.wrappedValue?.toUIKit()
        let hasChanges: Bool = {
            if #available(iOS 17.0, *), oldValue.prefersPageSizing != newValue.prefersPageSizing {
                return true
            }
            if #available(iOS 26.0, *), oldValue.prefersSheetInset != newValue.prefersSheetInset {
                return true
            }
            if oldValue.preferredCornerRadius != newValue.preferredCornerRadius {
                return true
            }
            if oldValue.prefersGrabberVisible != newValue.prefersGrabberVisible {
                return true
            }
            if oldValue.largestUndimmedDetentIdentifier != newValue.largestUndimmedDetentIdentifier {
                return true
            }
            if let selected = selectedDetentIdentifier,
                presentationController.selectedDetentIdentifier != selected
            {
                return true
            }
            if oldValue.detents != detents {
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
                presentationController.prefersGrabberVisible = newValue.prefersGrabberVisible
                presentationController.preferredCornerRadiusOptions = newValue.preferredCornerRadius
                if #available(iOS 17.0, *) {
                    presentationController.prefersPageSizing = newValue.prefersPageSizing
                }
                #endif
            }
            if let animation,
                !presentationController.presentedViewController.isBeingPresented,
                !presentationController.presentedViewController.isBeingDismissed
            {
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
