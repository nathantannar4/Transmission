//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

/// A presentation controller base class
@available(iOS 14.0, *)
open class PresentationController: DelegatedPresentationController {

    public private(set) var isTransitioningSize = false
    public private(set) var keyboardHeight: CGFloat = 0

    public let dimmingView: DimmingView = {
        let view = DimmingView()
        view.alpha = 0
        view.isHidden = true
        return view
    }()

    public class ShadowView: UIView {
        public weak var preferredSourceView: UIView?
    }
    public let shadowView = ShadowView()

    open var shouldAutoLayoutPresentedView: Bool {
        transition == nil
            && !isTransitioningSize
            && !presentedViewController.isBeingPresented
            && !presentedViewController.isBeingDismissed
    }

    /// The interactive transition driving the presentation or dismissal animation
    public weak var transition: UIPercentDrivenInteractiveTransition?

    open var wantsInteractiveTransition: Bool {
        return false
    }

    public var shouldIgnoreContainerViewTouches: Bool {
        get { containerView?.value(forKey: "ignoreDirectTouchEvents") as? Bool ?? false }
        set { containerView?.setValue(newValue, forKey: "ignoreDirectTouchEvents") }
    }

    public var presentedViewShadow: ShadowOptions = .clear {
        didSet {
            guard presentedViewController.isBeingPresented, presentedViewController.isBeingDismissed else { return }
            updateShadow(progress: 1)
        }
    }

    public override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    open func preferredDefaultAnimation() -> Animation? {
        return nil
    }

    open func attach(to transition: ViewControllerTransition) {
        if transition.animation == .default, let preferredDefaultAnimation = preferredDefaultAnimation() {
            transition.animation = preferredDefaultAnimation
        }
        transition.wantsInteractiveStart = wantsInteractiveTransition
        self.transition = transition
    }

    open override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        shouldIgnoreContainerViewTouches = true

        containerView?.addSubview(dimmingView)
        dimmingView.frame = containerView?.bounds ?? .zero
        dimmingView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didSelectBackground))
        )
        containerView?.addSubview(shadowView)
        if let presentedView {
            containerView?.addSubview(presentedView)
        }
        updateShadow(progress: 0)

        NotificationCenter.default
            .addObserver(
                self,
                selector: #selector(onKeyboardChange(_:)),
                name: UIResponder.keyboardWillChangeFrameNotification,
                object: nil
            )

        NotificationCenter.default
            .addObserver(
                self,
                selector: #selector(onKeyboardChange(_:)),
                name: UIResponder.keyboardWillHideNotification,
                object: nil
            )

        if let transitionCoordinator = presentedViewController.transitionCoordinator, transitionCoordinator.isAnimated {
            transitionCoordinator.animate { _ in
                self.transitionAlongsidePresentation(progress: 1)
            }
        }
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        if completed {
            transitionAlongsidePresentation(progress: 1)
        } else {
            NotificationCenter.default
                .removeObserver(
                    self,
                    name: UIResponder.keyboardWillChangeFrameNotification,
                    object: nil
                )

            NotificationCenter.default
                .removeObserver(
                    self,
                    name: UIResponder.keyboardWillHideNotification,
                    object: nil
                )

            transitionAlongsidePresentation(progress: 0)
        }
    }

    open override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        dimmingView.isUserInteractionEnabled = false
        updateShadow(progress: 1)

        if let transitionCoordinator = presentedViewController.transitionCoordinator, transitionCoordinator.isAnimated {
            transitionCoordinator.animate { _ in
                self.transitionAlongsidePresentation(progress: 0)
            }
        }
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            transitionAlongsidePresentation(progress: 0)

            NotificationCenter.default
                .removeObserver(
                    self,
                    name: UIResponder.keyboardWillChangeFrameNotification,
                    object: nil
                )

            NotificationCenter.default
                .removeObserver(
                    self,
                    name: UIResponder.keyboardWillHideNotification,
                    object: nil
                )
        } else {
            dimmingView.isUserInteractionEnabled = true
            transitionAlongsidePresentation(progress: 1)
        }
    }

    open func transitionAlongsidePresentation(progress: CGFloat) {
        dimmingView.alpha = progress
        layoutBackgroundViews()
        updateShadow(progress: progress)
    }

    open func transitionAlongsideRotation() {
        let frame = frameOfPresentedViewInContainerView
        layoutPresentedView(frame: frame)
    }

    open func updateShadow(progress: Double) {
        if presentedViewShadow == .clear {
            shadowView.isHidden = true
        } else {
            shadowView.isHidden = false
            var shadow = presentedViewShadow
            shadow.shadowOpacity *= Float(progress)
            shadow.apply(to: shadowView.layer)
        }
    }

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        if shouldAutoLayoutPresentedView {
            layoutPresentedView(frame: frameOfPresentedViewInContainerView)
        }
    }

    open override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        isTransitioningSize = true
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: containerView) { _ in
            self.transitionAlongsideRotation()
        } completion: { _ in
            self.isTransitioningSize = false
        }
    }

    open func layoutPresentedView(frame: CGRect) {
        presentedView?.setFramePreservingTransform(frame)
        presentedView?.layoutIfNeeded()
        layoutBackgroundViews()
    }

    open func layoutBackgroundViews() {
        layoutDimmingView()
        layoutShadowView()
    }

    open func layoutDimmingView() {
        if let presentationController = presentingViewController._activePresentationController {
            let frame = presentationController.presentedView?.frame ?? presentationController.frameOfPresentedViewInContainerView
            let dimmingViewFrame = presentingViewController.view.convert(
                presentingViewController.view.convert(
                    frame,
                    from: presentationController.containerView
                ),
                to: containerView
            )
            dimmingView.frame = dimmingViewFrame.rounded(scale: containerView?.window?.screen.scale ?? 1)
            if let presentedView = presentationController.presentedView ?? presentationController.presentedViewController.view {
                #if canImport(FoundationModels) // Xcode 26
                if #available(iOS 26.0, *) {
                    dimmingView.cornerConfiguration = presentedView.cornerConfiguration
                }
                #endif
                dimmingView.layer.cornerRadius = presentedView.layer.cornerRadius
                dimmingView.layer.cornerCurve = presentedView.layer.cornerCurve
                dimmingView.layer.maskedCorners = presentedView.layer.maskedCorners
            }
        } else if let presentedView = presentingViewController.view {
            let dimmingViewFrame = presentedView.convert(
                presentedView.bounds,
                to: containerView
            )
            dimmingView.frame = dimmingViewFrame.rounded(scale: containerView?.window?.screen.scale ?? 1)
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, *) {
                dimmingView.cornerConfiguration = presentedView.cornerConfiguration
            }
            #endif
            dimmingView.layer.cornerRadius = presentedView.layer.cornerRadius
            dimmingView.layer.cornerCurve = presentedView.layer.cornerCurve
            dimmingView.layer.maskedCorners = presentedView.layer.maskedCorners
        }
    }

    open func layoutShadowView() {
        guard let sourceView = shadowView.preferredSourceView ?? presentedView else { return }
        guard !shadowView.isHidden else { return }
        shadowView.transform = sourceView.transform
        shadowView.bounds = sourceView.bounds
        shadowView.center = sourceView.center
        shadowView.layer.shadowPath = CGPath(
            roundedRect: sourceView.bounds,
            cornerWidth: sourceView.layer.cornerRadius,
            cornerHeight: sourceView.layer.cornerRadius,
            transform: nil
        )
    }

    open func keyboardHeightDidChange() {
    }

    open func keyboardOverlapInContainerView(
        of frame: CGRect,
        keyboardHeight: CGFloat
    ) -> CGFloat {
        guard let containerView else { return 0 }
        let maxHeight = isTransitioningSize ? containerView.frame.width : containerView.frame.height
        let dy = maxHeight - keyboardHeight - (isTransitioningSize ? frame.maxX : frame.maxY)
        if dy < 0 {
            return abs(dy)
        }
        return 0
    }

    @objc
    private func onKeyboardChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            userInfo[UIResponder.keyboardIsLocalUserInfoKey] as? Bool != false
        else {
            return
        }

        let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        let dy = notification.name == UIResponder.keyboardWillHideNotification ? 0 : (endFrame?.size.height ?? 0)

        guard keyboardHeight != dy else { return }
        keyboardHeight = dy
        guard shouldAutoLayoutPresentedView, let containerView else {
            keyboardHeightDidChange()
            return
        }
        containerView.setNeedsLayout()

        guard
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            duration > 0,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else {
            keyboardHeightDidChange()
            containerView.layoutIfNeeded()
            return
        }
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [
                .init(rawValue: curve << 16),
                .beginFromCurrentState,
            ]
        ) {
            self.keyboardHeightDidChange()
            containerView.layoutIfNeeded()
        }
    }

    @objc
    private func didSelectBackground() {
        if presentedViewController.isBeingPresented {
            if let transition {
                let shouldDismiss = delegate?.presentationControllerShouldDismiss?(self) ?? true
                if shouldDismiss {
                    delegate?.presentationControllerWillDismiss?(self)
                    transition.cancel()
                    self.transition = nil
                    dimmingView.isUserInteractionEnabled = false
                }
            }
        } else if let next = presentedViewController.presentedViewController,
            let presentationController = next._activePresentationController as? PresentationController
        {
            presentationController.didSelectBackground()
        } else {
            let shouldDismiss = delegate?.presentationControllerShouldDismiss?(self) ?? true
            if shouldDismiss {
                presentedViewController.dismiss(animated: true)
            }
        }
    }
}

#endif
